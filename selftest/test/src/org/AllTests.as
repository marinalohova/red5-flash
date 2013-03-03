package org
{
  import asunit.framework.TestSuite;
  import org.red5.AllTests;

  /**
   * @private
   */
  public class AllTests extends TestSuite
  {
      public function AllTests()
      {
        addTest(new org.red5.AllTests());
      }
  }
}
