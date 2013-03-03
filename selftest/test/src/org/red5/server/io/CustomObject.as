package org.red5.server.io
{
  /**
   * This object is used by the custom object test to test marshalling
   * an object across the flash boundary, and making sure we get it back.
   */
  public class CustomObject
  {
    public var mNumber: Number = 123;

    public var mString: String = "yo ducky";

    public var mSelf:CustomObject = null;

    public function CustomObject(obj:Object=null)
    {
      // A reference to ourselves to make sure a server
      // doesn't choke on cyclic references.
      mSelf = this;

      if (obj != null)
      {
        mNumber = obj.mNumber;
        mString = obj.mString;
      }
    }

  }
}
