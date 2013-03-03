package org.red5
{
  import asunit.framework.TestSuite;
  import org.red5.server.AllTests;

  /**
   * @private
   */
  public class AllTests extends TestSuite
  {
      public function AllTests()
      {
        addTest(new org.red5.server.AllTests());
      }
  }
}
