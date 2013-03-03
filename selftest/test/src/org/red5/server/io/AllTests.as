package org.red5.server.io
{
  import asunit.framework.TestSuite;
  import org.red5.server.io.EchoStringTest;
  import org.red5.server.io.EchoStringTest;

  /**
   * @private
   */

  public class AllTests extends TestSuite
  {
      public function AllTests()
      {
        addTest(new org.red5.server.io.EchoStringTest());
        addTest(new org.red5.server.io.EchoArrayTest());
        addTest(new org.red5.server.io.EchoXMLTest());
        addTest(new org.red5.server.io.EchoObjectTest());
        addTest(new org.red5.server.io.EchoExternalizableObjectTest());
      }
  }
}
