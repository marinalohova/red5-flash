package org.red5.server
{
  import asunit.framework.TestSuite;
  import org.red5.server.io.AllTests;

  /**
   * @private
   */
  public class AllTests extends TestSuite
  {
      public function AllTests()
      {
        addTest(new org.red5.server.io.AllTests());
      }
  }
}
