/**
 * @author See Contributors.txt for code contributors and overview of BadgerDB.
 *
 * @section LICENSE
 * Copyright (c) 2012 Database Group, Computer Sciences Department, University of Wisconsin-Madison.
 */

#include "btree.h"
#include "filescan.h"
#include "exceptions/bad_index_info_exception.h"
#include "exceptions/bad_opcodes_exception.h"
#include "exceptions/bad_scanrange_exception.h"
#include "exceptions/no_such_key_found_exception.h"
#include "exceptions/scan_not_initialized_exception.h"
#include "exceptions/index_scan_completed_exception.h"
#include "exceptions/file_not_found_exception.h"
#include "exceptions/end_of_file_exception.h"
#include "exceptions/page_not_pinned_exception.h"
#include "exceptions/page_pinned_exception.h"
#define debugBadIndex
// #define DEBUGINSERTENTRY
// #define DEBUGFINDPLACEHELPER
// #define DEBUGLEAFSPLIT
// #define DEBUGINSERTLEAF
// #define GETPRARENT

namespace badgerdb
{

/**
 * True if root is a leaf, otherwise false
 */
bool rootIsLeaf = true;

// -----------------------------------------------------------------------------
// BTreeIndex::BTreeIndex -- Constructor
// -----------------------------------------------------------------------------

BTreeIndex::BTreeIndex(const std::string &relationName,
					   std::string &outIndexName,
					   BufMgr *bufMgrIn,
					   const int attrByteOffset,
					   const Datatype attrType)
{
	this->bufMgr = bufMgrIn;
	//------Create the name of index file------//
	std::ostringstream idxStr;
	idxStr << relationName << '.' << attrByteOffset;
	outIndexName = idxStr.str();

	//------Initialize some members------//
	this->attrByteOffset = attrByteOffset;
	this->attributeType = attrType;
	this->leafOccupancy = INTARRAYLEAFSIZE;
	this->nodeOccupancy = INTARRAYNONLEAFSIZE;
	this->scanExecuting = false;
	this->nextEntry = -1;
	this->currentPageNum = 0;
	this->headerPageNum = 1;

	//-----Open the index file if exist; otherwise create a new index file with the name created.-----//
	if (File::exists(outIndexName))
	{
		file = new BlobFile(outIndexName, false);
		//Read metaPage (first page) of the file
		Page *meta;
		headerPageNum = this->file->getFirstPageNo();
		this->bufMgr->readPage(this->file, headerPageNum, meta);
		IndexMetaInfo *metaPage = (IndexMetaInfo *)meta;
		this->rootPageNum = metaPage->rootPageNo;

		if (metaPage->attrByteOffset != attrByteOffset || metaPage->relationName != relationName || metaPage->attrType != attrType)
		{
			//Unpin the meta page before throwing the exception
			this->bufMgr->unPinPage(this->file, this->file->getFirstPageNo(), false);
			throw new badgerdb::BadIndexInfoException("MetaInfo mismatch!");
		}
		this->bufMgr->unPinPage(this->file, this->file->getFirstPageNo(), false);
	}
	//------Create new index file if the index file does not exist------//
	else
	{
		file = new BlobFile(outIndexName, true);
		//Create metainfo Page
		IndexMetaInfo *metaPage;
		Page *meta;
		this->bufMgr->allocPage(this->file, this->headerPageNum, meta);
		metaPage = (IndexMetaInfo *)meta;

		// Create a root node. This node is intialized as a leaf node.
		LeafNodeInt *rootNode;
		Page *root;
		this->bufMgr->allocPage(this->file, this->rootPageNum, root);
		rootNode = (LeafNodeInt *)root;
		rootNode->size = 0;
		rootNode->rightSibPageNo = 0;

		// Assign values to variables in metaPage
		strcpy(metaPage->relationName, relationName.c_str());
		metaPage->rootPageNo = this->rootPageNum;
		metaPage->attrByteOffset = attrByteOffset;
		metaPage->attrType = attributeType;

		// flush pages
		this->bufMgr->unPinPage(this->file, this->headerPageNum, true);
		this->bufMgr->unPinPage(this->file, this->rootPageNum, true);

		//Scan all tuples in the relation. Insert all tuples into the index.
		FileScan scn(relationName, bufMgrIn);
		try
		{
			RecordId scanRid;
			while (1)
			{
				scn.scanNext(scanRid);
				std::string recordStr = scn.getRecord();
				const char *record = recordStr.c_str();
				void *key = (void *)(record + this->attrByteOffset);
				insertEntry(key, scanRid);
			}
		}
		catch (const badgerdb::EndOfFileException &e)
		{
			std::cout << "All records has been read" << '\n';
		}
	}
}

// -----------------------------------------------------------------------------
// BTreeIndex::~BTreeIndex -- destructor
// -----------------------------------------------------------------------------
BTreeIndex::~BTreeIndex()
{

	try
	{
		if (this->currentPageNum)
		{
			this->bufMgr->unPinPage(this->file, this->currentPageNum, false);
		}

		if (this->scanExecuting)
		{
			this->endScan();
		}

		if (this->file)
		{
			this->bufMgr->flushFile(this->file);
			delete this->file;
			this->file = NULL;
		}
	}
	catch (badgerdb::BadgerDbException e)
	{
		std::cerr << e.what() << '\n';
	}
}

// -----------------------------------------------------------------------------
// BTreeIndex::insertEntry
// -----------------------------------------------------------------------------
const void BTreeIndex::insertEntry(const void *key, const RecordId rid)
{
	std::cout << *((int *)key) << std::endl;
	if (this->rootPageNum == 2)
	{ // This means root is a leaf.
		insertLeaf(key, rid, this->rootPageNum);
		return;
	}
	// The root is a nonleafNode
	PageId pageToInsert = FindPlaceHelper(key, this->rootPageNum);
	insertLeaf(key, rid, pageToInsert);
}

// -----------------------------------------------------------------------------
// BTreeIndex::FindPlaceHelper
// -----------------------------------------------------------------------------
PageId BTreeIndex::FindPlaceHelper(const void *key, PageId pageNo)
{
	Page *tmp;
	this->bufMgr->readPage(this->file, pageNo, tmp);
	NonLeafNodeInt *curNode = (NonLeafNodeInt *)tmp;
	this->bufMgr->unPinPage(this->file, pageNo, false);
	// Find the index to insert in the page, and find the corresponding child page
	int index = getIndexNonLeaf(pageNo, key);
	PageId nextLevelPage = curNode->pageNoArray[index];
	// If the page is one level above the leaf
	if (curNode->level == 1)
		return nextLevelPage;
	// Else, recursively find the right page to insert
	return FindPlaceHelper(key, nextLevelPage);
}

// -----------------------------------------------------------------------------
// BTreeIndex::insertLeaf
// -----------------------------------------------------------------------------
const void BTreeIndex::insertLeaf(const void *key, RecordId rid, PageId pageNo)
{
	Page *tmp;
	this->bufMgr->readPage(this->file, pageNo, tmp);
	LeafNodeInt *leafNode = (LeafNodeInt *)tmp;
	RIDKeyPair<int> pair;
	pair.set(rid, *((int *)key));

	// If the leaf node is empty
	if (!leafNode->size)
	{
		leafNode->keyArray[leafNode->size] = pair.key;
		leafNode->ridArray[leafNode->size++] = pair.rid;
		this->bufMgr->unPinPage(this->file, pageNo, true);
		return;
	}

	int index = getIndexLeaf(pageNo, key);

	/*---Check if need to split. If so, split and insert---*/
	if (leafNode->size == this->leafOccupancy)
	{
		splitAndInsert(pageNo, key, rid);
		this->bufMgr->unPinPage(this->file, pageNo, false);
		return;
	}
	// Move every entry from i to i+1 since we are inserting at i. In this case, no need to change parent's entry
	for (int j = leafNode->size - 1; j >= index; j--)
	{
		leafNode->keyArray[j + 1] = leafNode->keyArray[j];
		leafNode->ridArray[j + 1] = leafNode->ridArray[j];
	}
	//insert at index
	leafNode->keyArray[index] = pair.key;
	leafNode->ridArray[index] = pair.rid;
	leafNode->size++;

	//Since inserted, the page is dirty
	try
	{
		this->bufMgr->unPinPage(this->file, pageNo, true);
	}
	catch (const badgerdb::PageNotPinnedException &e)
	{
		std::cerr << "insertLeaf: exception thrown after all insertion \t" << e.what() << '\n';
	}
}

// -----------------------------------------------------------------------------
// BTreeIndex::splitAndInsert
// -----------------------------------------------------------------------------
const void BTreeIndex::splitAndInsert(PageId pageNo, const void *key, RecordId rid)
{
	Page *tmp;
	this->bufMgr->readPage(this->file, pageNo, tmp);
	LeafNodeInt *leftNode = (LeafNodeInt *)tmp;
	RIDKeyPair<int> pair;
	pair.key = *((int *)key);
	pair.rid = rid;

	//------Construct a new page------//
	Page *newPage;
	PageId newPageId;
	this->bufMgr->allocPage(this->file, newPageId, newPage);
	LeafNodeInt *newNode = (LeafNodeInt *)newPage;

	// Update the right sibling page number
	newNode->rightSibPageNo = leftNode->rightSibPageNo;
	leftNode->rightSibPageNo = newPageId;

	int size = leftNode->size; //Same as leaf occupancy
	int mid = size / 2 + size % 2;

	// Move the floor (size / 2) of the original page to new page
	memcpy(&newNode->keyArray[0], &leftNode->keyArray[mid], sizeof(int) * (size - mid));
	memcpy(&newNode->ridArray[0], &leftNode->ridArray[mid], sizeof(RecordId) * (size - mid));
	leftNode->size = mid;
	newNode->size = size - mid;

	PageId parentPageId = getParent(pageNo, key);
	// Edge case: Root is the leaf, and there is no parent(there is only one leaf node in the btree, and the pageNo = 2)
	if (!parentPageId)
	{
		splitRoot();
		parentPageId = this->rootPageNum;
		Page *tmp;
		this->bufMgr->readPage(this->file, parentPageId, tmp);
		NonLeafNodeInt *root = (NonLeafNodeInt *)tmp;
		// Update root
		root->size = 1;
		root->level = 1;
		root->keyArray[0] = leftNode->keyArray[mid - 1];
		root->pageNoArray[0] = pageNo;
		root->pageNoArray[1] = newPageId;
		this->bufMgr->unPinPage(this->file, parentPageId, true);
	}
	else
	{
		insertInternal(&leftNode->keyArray[mid - 1], parentPageId, newPageId);
	}
	// determine on which page to insert the new key
	if (*(int *)key >= leftNode->keyArray[mid])
	{
		// Then add the new key into the right (new) leaf
		insertLeaf(key, rid, newPageId);
	}
	else
	{
		insertLeaf(key, rid, pageNo);
	}

	//Unpin pages
	try
	{
		this->bufMgr->unPinPage(this->file, pageNo, true);
		this->bufMgr->unPinPage(this->file, newPageId, true);
	}
	catch (const badgerdb::PageNotPinnedException &e)
	{
		std::cerr << "splitAndInsert: exception thrown when closing the original and new leaf node\t" << e.what() << '\n';
	}
}

// -----------------------------------------------------------------------------
// BTreeIndex::insertInternal
// -----------------------------------------------------------------------------
const void BTreeIndex::insertInternal(const void *key, PageId parentPageNo, PageId childPageNo)
{
	Page *tmp;
	this->bufMgr->readPage(this->file, parentPageNo, tmp);
	NonLeafNodeInt *parentNode = (NonLeafNodeInt *)tmp;
	// Get the index to insert
	int index = getIndexNonLeaf(parentPageNo, key);

	/*--- Check if need to split---*/
	if (parentNode->size == INTARRAYNONLEAFSIZE)
	{
		splitAndInsertInternal(parentPageNo, key, childPageNo);
	}
	// No need to split
	else
	{
		for (int j = parentNode->size - 1; j >= index; j--)
		{
			parentNode->keyArray[j + 1] = parentNode->keyArray[j];
			parentNode->pageNoArray[j + 2] = parentNode->pageNoArray[j + 1];
		}
		//insert at index
		parentNode->keyArray[index] = *(int *)key;
		parentNode->pageNoArray[index + 1] = childPageNo;
		parentNode->size++;
	}
	try
	{
		this->bufMgr->unPinPage(this->file, parentPageNo, true);
	}
	catch (const badgerdb::PageNotPinnedException &e)
	{
		std::cerr << "insertInternal: exception thrown when closing the parent page \t" << e.what() << '\n';
	}
}

// -----------------------------------------------------------------------------
// BTreeIndex::insertAndSplitInternal
// -----------------------------------------------------------------------------
const void BTreeIndex::splitAndInsertInternal(PageId leftPageNo, const void *key, PageId pageInPair)
{
	Page *tmp;
	this->bufMgr->readPage(this->file, leftPageNo, tmp);
	NonLeafNodeInt *leftNode = (NonLeafNodeInt *)tmp;
	//------Construct a new page------//
	Page *newPage;
	PageId newPageNo;
	this->bufMgr->allocPage(this->file, newPageNo, newPage);
	NonLeafNodeInt *newNode = (NonLeafNodeInt *)newPage;
	// Update level
	newNode->level = leftNode->level;
	// Create a pair to insert
	PageKeyPair<int> pair;
	pair.set(pageInPair, *((int *)key));

	int mid = (nodeOccupancy - 1) / 2;

	/* Algorithm: first split the node into two nodes, then insert the keyPagePair to either node (call insertInternal).
	 * When splitting, push up the max key of the left node. Here call insertInternal again. In this way, all chained-splits
	 * should be handled during the recursive call between insertInternal() and insertAndSplitInternal().
	 * Note that if we reach the root and need to split the root, call the helper method splitRoot() and manually set the 
	 * new root to be the parent node.
	*/

	memcpy(&newNode->keyArray[0], &leftNode->keyArray[mid + 1], sizeof(int) * (nodeOccupancy - mid - 1));
	memcpy(&newNode->pageNoArray[0], &leftNode->pageNoArray[mid + 1], sizeof(PageId) * (nodeOccupancy - mid));
	leftNode->size = mid;
	newNode->size = nodeOccupancy - mid - 1;

	PageId parentPageId = getParent(leftPageNo, key);
	// Edge case: Check if the leftNode is the root node. If so, split the root
	if (!parentPageId)
	{
		splitRoot();
		parentPageId = this->rootPageNum;
		Page *tmp;
		this->bufMgr->readPage(this->file, parentPageId, tmp);
		NonLeafNodeInt *root = (NonLeafNodeInt *)tmp;
		// Update root
		root->size = 1;
		root->level = 0;
		root->keyArray[0] = leftNode->keyArray[mid];
		root->pageNoArray[0] = leftPageNo;
		root->pageNoArray[1] = newPageNo;
		this->bufMgr->unPinPage(this->file, parentPageId, true);
	}
	else
	{
		insertInternal(&leftNode->keyArray[mid], parentPageId, newPageNo);
	}

	if (pair.key >= leftNode->keyArray[mid])
	{
		insertInternal(key, newPageNo, pair.pageNo);
	}
	else
	{
		insertInternal(key, leftPageNo, pair.pageNo);
	}
	try
	{
		this->bufMgr->unPinPage(this->file, leftPageNo, true);
		this->bufMgr->unPinPage(this->file, newPageNo, true);
	}
	catch (const badgerdb::PageNotPinnedException &e)
	{
		std::cerr << "splitAndInsertInternal: exception thrown when closing the original and new pages\t" << e.what() << '\n';
	}
}

// -----------------------------------------------------------------------------
// BTreeIndex::splitRoot
// -----------------------------------------------------------------------------
const void BTreeIndex::splitRoot()
{
	// First check if the root is a leaf. This is relevant to level assignment.
	bool rootIsLeaf = 0;
	if (this->rootPageNum == 2)
	{
		rootIsLeaf = 1;
	}
	Page *newRoot;
	PageId newRootId;
	this->bufMgr->allocPage(this->file, newRootId, newRoot);
	NonLeafNodeInt *newRootNode = (NonLeafNodeInt *)newRoot;
	this->rootPageNum = newRootId;
	// If before split the root is a leaf, then now the root is 1 level above the leaf so assign 1. Otherwise assign 0.
	newRootNode->level = rootIsLeaf ? 1 : 0;
	newRootNode->size = 0;
	this->bufMgr->unPinPage(this->file, newRootId, true);

	Page *tmp;
	bufMgr->readPage(file, headerPageNum, tmp);
	IndexMetaInfo *metaPage = (IndexMetaInfo *)tmp;
	metaPage->rootPageNo = newRootId;
	bufMgr->unPinPage(file, headerPageNum, true);
}

// -----------------------------------------------------------------------------
// BTreeIndex::getParent
// -----------------------------------------------------------------------------
PageId BTreeIndex::getParent(PageId childPageNo, const void *key)
{
	if (*((int *)key) == 1023)
	{
		std::cout << "a" << std::endl;
	}
	// This means there's no parent for the given node
	if (childPageNo == rootPageNum)
	{
		return 0;
	}
	PageId parentNo = rootPageNum; // Parent starts from the root
	while (1)
	{
		Page *tmp;
		this->bufMgr->readPage(this->file, parentNo, tmp);
		NonLeafNodeInt *parentCurNode = (NonLeafNodeInt *)tmp;
		this->bufMgr->unPinPage(this->file, parentNo, tmp);
		PageId childCurNo = parentCurNode->pageNoArray[getIndexNonLeaf(parentNo, key)];

		if (childCurNo == childPageNo)
		{
			return parentNo;
		}
		parentNo = childCurNo;
	}
}

// -----------------------------------------------------------------------------
// BTreeIndex::getIndexNonLeaf
// -----------------------------------------------------------------------------
int BTreeIndex::getIndexNonLeaf(PageId pageNo, const void *key)
{
	Page *tmp;
	this->bufMgr->readPage(this->file, pageNo, tmp);
	NonLeafNodeInt *curNode = (NonLeafNodeInt *)tmp;
	try
	{
		this->bufMgr->unPinPage(this->file, pageNo, false);
	}
	catch (const badgerdb::PageNotPinnedException &e)
	{
		std::cerr << "getIndexNonLeaf: exception thrown after computing the index\t" << e.what() << '\n';
	}

	// Check if the node is empty
	if (!curNode->size)
	{
		return 0;
	}
	// Find out the index
	for (int i = 0; i < curNode->size; i++)
	{
		if (curNode->keyArray[i] >= *((int *)key))
		{
			return i;
		}
	}

	//Return the last index
	return curNode->size;
}

// -----------------------------------------------------------------------------
// BTreeIndex::getIndexLeaf
// -----------------------------------------------------------------------------
int BTreeIndex::getIndexLeaf(PageId pageNo, const void *key)
{
	Page *tmp;
	this->bufMgr->readPage(this->file, pageNo, tmp);
	LeafNodeInt *curNode = (LeafNodeInt *)tmp;
	// Check if the node is empty
	try
	{
		this->bufMgr->unPinPage(this->file, pageNo, false);
	}
	catch (const badgerdb::PageNotPinnedException &e)
	{
		std::cerr << "getIndexLeaf: Exception thrown after computing the index\t" << e.what() << '\n';
	}

	if (!curNode->size)
	{
		return 0;
	}
	// Find out the index
	for (int i = 0; i < curNode->size; i++)
	{
		if (curNode->keyArray[i] >= *((int *)key))
		{
			// this->bufMgr->unPinPage(this->file, pageNo, false);
			return i;
		}
	}
	//Return the last index
	return curNode->size;
}

// -----------------------------------------------------------------------------
// BTreeIndex::startScan
// -----------------------------------------------------------------------------
const void BTreeIndex::startScan(const void *lowValParm,
								 const Operator lowOpParm,
								 const void *highValParm,
								 const Operator highOpParm)
{

	// TODO: If another scan is already executing, that needs to be ended here.
	if (scanExecuting)
	// if (scanExecuting || currentPageData != NULL)
	{
		currentPageData = NULL;
	}
	if ((lowOpParm != GT && lowOpParm != GTE) || (highOpParm != LT && highOpParm != LTE))
	{
		throw BadOpcodesException();
	}

	if (*(int *)lowValParm > *(int *)highValParm)
	{
		throw BadScanrangeException();
	}

	// set vars for scan
	lowValInt = *(int *)lowValParm;
	highValInt = *(int *)highValParm;
	lowOp = lowOpParm;
	highOp = highOpParm;
	nextEntry = 0;
	scanExecuting = true;
	std::cout << "root num:" << rootPageNum << std::endl;
	// read and unpin the root
	Page *root;
	this->bufMgr->readPage(this->file, rootPageNum, root);
	this->bufMgr->unPinPage(this->file, rootPageNum, false);
	// if root is a leaf, directly check whether the root's keys are in the range

	if (this->rootPageNum == 2)
	{
		LeafNodeInt *rootNode = (LeafNodeInt *)root;

		if (((highOpParm == LT) && (rootNode->keyArray[0] >= *(int *)highValParm)) ||
			((highOpParm == LTE) && (rootNode->keyArray[0] > *(int *)highValParm)) ||
			((lowOpParm == GT) && (rootNode->keyArray[rootNode->size - 1] < *(int *)lowValParm)) ||
			((lowOpParm == GTE) && (rootNode->keyArray[rootNode->size - 1] <= *(int *)lowValParm)))
		{
			throw NoSuchKeyFoundException();
		}
		// this->bufMgr->readPage(this->file, rootPageNum, root);
	}
	else // traver from root if it is a noneleaf
	{
		bool reachLeaf = false;
		NonLeafNodeInt *rootNode = (NonLeafNodeInt *)root;
		Page *currPage = root;
		NonLeafNodeInt *currNode = rootNode;

		// find the leaf node of contains lower bound
		while (!reachLeaf)
		{
			for (int i = 0; i < currNode->keyArray[rootNode->size - 1]; i++)
			{
				// ">" lowVal
				if (lowOpParm == GT && currNode->keyArray[i] > *(int *)lowValParm)
				{
					if (currNode->level == 1) // next level is leaf node
					{
						// assign the correct leaf page to be the first leaf page contain the lower bound
						this->bufMgr->readPage(this->file, currNode->pageNoArray[i], this->currentPageData);
						currentPageNum = currNode->pageNoArray[i];
						this->bufMgr->unPinPage(this->file, currNode->pageNoArray[i], false);
						reachLeaf = true;
						break;
					}
					// traverse to child if i th key is greater than the low bound
					this->bufMgr->readPage(this->file, currNode->pageNoArray[i], currPage);
					this->bufMgr->unPinPage(this->file, currNode->pageNoArray[i], false);
					currNode = (NonLeafNodeInt *)currPage;
					break;
				} // ">=" lowVal
				else if (lowOpParm == GTE && currNode->keyArray[i] >= *(int *)lowValParm)
				{
					if (currNode->level == 1)
					{
						this->bufMgr->readPage(this->file, currNode->pageNoArray[i], this->currentPageData);
						currentPageNum = currNode->pageNoArray[i];
						this->bufMgr->unPinPage(this->file, currNode->pageNoArray[i], false);
						reachLeaf = true;
						break;
					}
					// traverse to child if i th key is greater or equal than the low bound
					this->bufMgr->readPage(this->file, currNode->pageNoArray[i], currPage);
					this->bufMgr->unPinPage(this->file, currNode->pageNoArray[i], false);
					currNode = (NonLeafNodeInt *)currPage;
					break;
				}
			}
		}
		if (this->currentPageData == NULL)
		{
			// scanExecuting = false;
			throw NoSuchKeyFoundException();
		}
	}
}

const bool BTreeIndex::inRange(int value)
{
	if (lowOp == GT && highOp == LT && value > lowValInt && value < highValInt)
		return true;
	if (lowOp == GT && highOp == LTE && value > lowValInt && value <= highValInt)
		return true;
	if (lowOp == GTE && highOp == LT && value >= lowValInt && value < highValInt)
		return true;
	if (lowOp == GTE && highOp == LTE && value >= lowValInt && value <= highValInt)
		return true;
	return false;
}
// -----------------------------------------------------------------------------
// BTreeIndex::scanNext
// -----------------------------------------------------------------------------
const void BTreeIndex::scanNext(RecordId &outRid)
{
	if (scanExecuting == false || currentPageData == NULL)
	{
		throw ScanNotInitializedException();
	}

	while (1)
	{
		this->bufMgr->readPage(this->file, currentPageNum, currentPageData);
		this->bufMgr->unPinPage(this->file, currentPageNum, false);
		LeafNodeInt *currNode = (LeafNodeInt *)currentPageData;

		// if the first key of currNode > the high bound, stop scanning
		if ((lowOp == GT && currNode->keyArray[0] >= highValInt) || (lowOp == GTE && currNode->keyArray[0] > highValInt))
		{
			throw IndexScanCompletedException();
		}
		while (nextEntry < currNode->size) // keep scanning the current node until reach the last entry
		{
			// fetch the record id if the entry match the scan
			if (inRange(currNode->keyArray[nextEntry]))
			{
				outRid = currNode->ridArray[nextEntry];
				nextEntry++;
				return;
			}
			else  // go to next entry of current node
			{
				nextEntry++;
			}
		}
		// move to the right sibling if the current page is entirely scannned
		if (currNode->rightSibPageNo == 0) //read the last leaf node
		{
			throw IndexScanCompletedException();
		}
		currentPageNum = currNode->rightSibPageNo;
		nextEntry = 0;
	}
} // namespace badgerdb

// -----------------------------------------------------------------------------
// BTreeIndex::endScan
// -----------------------------------------------------------------------------
//
const void BTreeIndex::endScan()
{
	// TODO: criteria for not initialized scan
	if (scanExecuting == false)
	{
		throw ScanNotInitializedException();
	}
	// reset vars for scan
	currentPageData = NULL;
	currentPageNum = 0;
	scanExecuting = false;
	nextEntry = -1;
}

} // namespace badgerdb
