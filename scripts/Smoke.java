import java.sql.*;
public class Smoke {
  public static void main(String[] a) throws Exception {
    try (Connection c = DriverManager.getConnection("jdbc:h2:tcp://localhost:" + a[0] + "/test", "sa", "");
         Statement s = c.createStatement()) {
      s.execute("create table t(i int)"); s.execute("insert into t values(42)");
      ResultSet r = s.executeQuery("select i from t"); r.next();
      if (r.getInt(1) != 42) throw new IllegalStateException("basic");
      // Java source compiled by the server (needs jdk.compiler)
      s.execute("create alias suma as $$ int suma(int a, int b) { return a + b; } $$");
      r = s.executeQuery("select suma(40, 2)"); r.next();
      if (r.getInt(1) != 42) throw new IllegalStateException("alias");
      // Locale-specific collation (needs jdk.localedata)
      s.execute("drop table t"); s.execute("set collation french");
      r = s.executeQuery("select formatdatetime(date '2024-01-15', 'MMMM', 'es')"); r.next();
      if (!"enero".equals(r.getString(1))) throw new IllegalStateException("locale: " + r.getString(1));
      // Extended charset (needs jdk.charsets)
      s.execute("call csvwrite('smoke.csv', 'select 1 a', 'charset=Shift_JIS')");
    }
  }
}
