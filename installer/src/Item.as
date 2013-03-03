package {
    [Bindable]

    public class Item {
        public var name:String;
        public var description:String;
        public var author:String;
        public var filename:String;
        public var javaVersion:String;

        public function Item() {
        }

        public function toString():String {
            return "[Item]" + this.name;
        }
    }
}