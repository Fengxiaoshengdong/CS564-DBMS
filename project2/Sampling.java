import java.sql.*;
import java.util.*;

public class Sampling{
    static Integer seed = null;

    /**
     * the method to deal with the request that the user want to sample from the
     * table
     *
     * @param st
     * @param rs
     * @param tableName
     * @param newTable
     * @param n
     * @param createTb
     * @throws SQLException
     */
    public static void table(Statement st, ResultSet rs, String tableName, String newTable, int n, boolean createTb)
        throws SQLException {
        int t = 0; // total number of input records we ave dealt with
        int m = 0; // the number of records selected so far
        int N; // total number of records we read from
        double U; // random number uniformly distributed from 0 to 1
        Random random;

        // get the total number of record from the table
        rs = st.executeQuery("SELECT count(*) FROM " + tableName + ";");
        rs.next();
        N = rs.getInt(1);
        st.executeUpdate("DROP View IF exists view2;");
        st.executeUpdate("DROP View IF exists view1;");
        // indexing the original table as view2
        st.executeUpdate("CREATE VIEW view1 as (SELECT *, ROW_NUMBER() OVER() as ROWNUMBER FROM " + tableName + ");");
        if (seed != null) {
            random = new Random(seed);
        } else {
            random = new Random();
        }

        rs = st.executeQuery("SELECT * FROM view1 WHERE ROWNUMBER = 1;");
        ResultSetMetaData rsMetaData = rs.getMetaData();
        int numberOfColumns = rsMetaData.getColumnCount();

        ArrayList<String> cols = new ArrayList<>(); // the column name list
        ArrayList<String> types = new ArrayList<>(); // column type list
        // get the column names; column indexes start from 1
        for (int i = 1; i < numberOfColumns; i++) {
            cols.add(rsMetaData.getColumnName(i));
            types.add(JDBCType.valueOf(rsMetaData.getColumnType(i)).getName());
            System.out.print(cols.get(i - 1) + "\t");
        }
        System.out.println();

        String sql = "CREATE TABLE \"" + newTable + "\"(";
        for (int i = 0; i < cols.size() - 1; i++) {
            if (types.get(i).toLowerCase().equals("double")){
                types.set(i, "DOUBLE PRECISION");
            }else if (types.get(i).toLowerCase().equals("bit")){
                types.set(i, "BOOLEAN");
            }
            sql +=  "\"" + cols.get(i) + "\" " + types.get(i) + ", ";
        }
        if (types.get(types.size() - 1).toLowerCase().equals("double")){
            types.set(types.size() - 1, "DOUBLE PRECISION");
        }else if (types.get(types.size() - 1).toLowerCase().equals("bit")){
            types.set(types.size()- 1, "BOOLEAN");
        }
        sql += "\"" + cols.get(cols.size() - 1) + "\" " + types.get(types.size() - 1) + ");";
        if (createTb) { // create new table in data base if user would like to
            st.executeUpdate("DROP Table IF exists " + newTable + ";");
            st.executeUpdate(sql);
        }
        int index = 1;

        while (m < n) {
            U = random.nextDouble();
            if ((N - t) * U >= (n - m)) { // not select the record
                t++;
            } else { // select the record
                m++;
                t++;
                rs = st.executeQuery("SELECT * FROM view1 WHERE ROWNUMBER = " + index + ";");
                String insertSQL = "INSERT INTO " + newTable + " VALUES ( ";
                if(!rs.next()) break;
                for (int i = 1; i < numberOfColumns; i++) {
                    System.out.print(rs.getObject(i) + "\t");
                    insertSQL += "'" + rs.getObject(i) + "',";
                }
                System.out.println();
                insertSQL = insertSQL.substring(0, insertSQL.length() - 1) + ");";
                if (createTb) { // insert the record to the new table created
                    st.executeUpdate(insertSQL);
                }
            }
            index++;
        }
    }

    /**
     * the method to deal with the sql query the user wants to sample from
     *
     * @param st
     * @param rs
     * @param query
     * @param newTable
     * @param n
     * @param createTb
     * @throws SQLException
     */
    public static void query(Statement st, ResultSet rs, String query, String newTable, int n, boolean createTb)
        throws SQLException {
        int t = 0; // total number of input records we ave dealt with
        int m = 0; // the number of records selected so far
        int N; // total number of records we read from
        double U; // random number uniformly distributed from 0 to 1
        Random random;

        st.executeUpdate("DROP View IF exists view2;");
        st.executeUpdate("DROP View IF exists view1;");
        st.executeUpdate("CREATE VIEW view1 as (" + query + ");");

        // get the total number of record from the table
        rs = st.executeQuery("SELECT count(*) FROM view1;");
        rs.next();
        N = rs.getInt(1);

        // indexing the original table as view2
        st.executeUpdate("CREATE VIEW view2 as (SELECT *, ROW_NUMBER() OVER() as ROWNUMBER FROM view1);");

        if (seed != null) {
            random = new Random(seed);
        } else {
            random = new Random();
        }
        ArrayList<String> cols = new ArrayList<>(); // the column name list
        ArrayList<String> types = new ArrayList<>(); // column type list

        rs = st.executeQuery("SELECT * FROM view2 WHERE ROWNUMBER = 1;");
        ResultSetMetaData rsMetaData = rs.getMetaData();
        int numberOfColumns = rsMetaData.getColumnCount();
        // get the column names; column indexes start from 1
        for (int i = 1; i < numberOfColumns; i++) {
            cols.add(rsMetaData.getColumnName(i));
            types.add(JDBCType.valueOf(rsMetaData.getColumnType(i)).getName());
            System.out.print(cols.get(i - 1) + "\t");
        }
        System.out.println();

        String sql = "CREATE TABLE \"" + newTable + "\"(";
        for (int i = 0; i < cols.size() - 1; i++) {
            if (types.get(i).toLowerCase().equals("double")){
                types.set(i, "DOUBLE PRECISION");
            }else if (types.get(i).toLowerCase().equals("bit")){
                types.set(i, "BOOLEAN");
            }
            sql +=  "\"" + cols.get(i) + "\" " + types.get(i) + ", ";
        }
        if (types.get(types.size() - 1).toLowerCase().equals("double")){
            types.set(types.size() - 1, "DOUBLE PRECISION");
        }else if (types.get(types.size() - 1).toLowerCase().equals("bit")){
            types.set(types.size()- 1, "BOOLEAN");
        }
        sql += "\"" + cols.get(cols.size() - 1) + "\" " + types.get(types.size() - 1) + ");";
        if (createTb) { // create table if the user choose to
//            System.out.println(sql);
            st.executeUpdate("DROP Table IF exists " + newTable + ";");
            st.executeUpdate(sql);
        }
        int index = 1;

        while (m < n) {
            U = random.nextDouble();
            if ((N - t) * U >= (n - m)) { // not select the record to sample
                t++;
            } else { // select the record
                m++;
                t++;
                rs = st.executeQuery("SELECT * FROM view2 WHERE ROWNUMBER = " + index + ";");
                String insertSQL = "INSERT INTO " + newTable + " VALUES ( ";
                //
                if (!rs.next()) break;
                for (int i = 1; i < numberOfColumns; i++) {
                    System.out.print(rs.getObject(i) + "\t");
                    insertSQL += "'" + rs.getObject(i) + "',";
                }
                System.out.println();
                insertSQL = insertSQL.substring(0, insertSQL.length() - 1) + ");";
                if (createTb) { // insert the record to sample table
                    st.executeUpdate(insertSQL);
                }
            }
            index++;
        }
    }

    public static void main(String[] args) throws Exception {
        Connection conn = null;
        Statement st = null;
        ResultSet rs = null;
        try {
            String url = "jdbc:postgresql://stampy.cs.wisc.edu/cs564instr?sslfactory=org.postgresql.ssl.NonValidatingFactory&ssl";
            conn = DriverManager.getConnection(url);
            st = conn.createStatement();
            Scanner scanner = new Scanner(System.in);

            String input; // input read from the user
            int n = -1; // the number of rows user want to sample

            boolean createTb;

            while (true) {
                n = -1;
                System.out.println("Type \"1\" if you want to enter a table\n"
                    + "Type \"2\" if you want to enter a query\n" + "Type \"q\" if you want to quit");
                input = scanner.nextLine();
                String newTable = null; // the table name user want to create

                if (input.equals("1")) { // user choose to sample from table
                    do {
                        System.out.println("Enter the number of sample rows you want (integer)");
                        try{
                            n = scanner.nextInt();
                        } catch (InputMismatchException e){}
                        scanner.nextLine();
                    } while (n == -1);
                    System.out.println(
                        "Type \"t\" if you want to create tables for sampled rows, otherwise we will print the result sampled rows");
                    if (scanner.nextLine().toLowerCase().equals("t")) {
                        createTb = true;
                        System.out.println("Enter the table name you want to create");
                        newTable = scanner.nextLine();
                    } else {
                        createTb = false;
                    }
                    System.out.println(
                        "Enter the integer you want to set as the random seed, otherwise press any letter");

                    try{
                        seed =  scanner.nextInt();

                    }catch (InputMismatchException e) {
                        seed = null;

                    }
                    scanner.nextLine();
                    System.out.println("Enter the table name you want to sample from");
                    input = scanner.nextLine();
                    table(st, rs, input, newTable, n, createTb);
                } else if (input.equals("2")) { // user want to sample from specific query
                    do {
                        System.out.println("Enter the number of sample rows you want (integer)");
                        try{
                            n = scanner.nextInt();
                        } catch (InputMismatchException e){}
                        scanner.nextLine();
                    } while (n == -1);
                    System.out.println(
                        "Type \"t\" if you want to create tables for sampled rows, otherwise we will print the result sampled rows");
                    if (scanner.nextLine().toLowerCase().equals("t")) {
                        createTb = true;
                        System.out.println("Enter the table name you want to create");
                        newTable = scanner.nextLine();
                    } else {
                        createTb = false;
                    }
                    System.out.println(
                        "Enter the integer you want to set as the random seed, otherwise press any letter");

                    try{
                        seed =  scanner.nextInt();

                    }catch (InputMismatchException e) {
                        seed = null;

                    }
                    scanner.nextLine();

                    System.out.println("Enter the query you want to sample");
                    input = scanner.nextLine();
                    // read the user input as sql query until the ;
                    while (!input.contains(";") && scanner.hasNextLine()) {
                        input += scanner.nextLine() + " ";
                    }
                    input = input.split(";")[0];

                    query(st, rs, input, newTable, n, createTb);
                } else if (input.toLowerCase().equals("q")) {
                    break;
                }
            }
        } catch (Exception e) {
            System.out.println("Exception caught! Info:");
            e.printStackTrace();
            System.out.println("Exiting program.");
        } finally {
            if (rs != null) {
                rs.close();
            }
            if (st != null) {
                st.close();
            }
            if (conn != null) {
                conn.close();
            }
        }
    }
}
