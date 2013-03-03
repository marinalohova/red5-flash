/**
 * RED5 Open Source Flash Server - http://www.osflash.org/red5
 *
 * Copyright (c) 2006-2009 by respective authors (see below). All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free Software
 * Foundation; either version 2.1 of the License, or (at your option) any later
 * version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License along
 * with this library; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/
package org.red5.samples.echo.model 
{
	import org.red5.samples.echo.model.tests.*;
	import org.red5.samples.echo.vo.TestSelection;
	
	/**
	 * Sample data for AMF0 and AMF3 data type tests.
	 * 
	 * @author Joachim Bauch (jojo@struktur.de)
	 * @author Thijs Triemstra (info@collab.nl)
	 */
	public class EchoTestData
	{
		private var _items				: Array;
		private var _amf0count 			: Number;
		
		private var _nullTest			: NullTest = new NullTest();
		private var _undefinedTest		: UndefinedTest = new UndefinedTest();
		private var _booleanTest		: BooleanTest = new BooleanTest();
		private var _stringTest			: StringTest = new StringTest();
		private var _numberTest			: NumberTest = new NumberTest();
		private var _arrayTest			: ArrayTest = new ArrayTest();
		private var _objectTest			: ObjectTest = new ObjectTest();
		private var _dateTest			: DateTest = new DateTest();
		private var _xmlDocumentTest	: XMLDocumentTest = new XMLDocumentTest();
		private var _customClassTest	: CustomClassTest = new CustomClassTest();
		private var _remoteClassTest	: RemoteClassTest = new RemoteClassTest();
		private var _xmlTest			: XMLTest = new XMLTest();
		private var _externalizableTest	: ExternalizableTest = new ExternalizableTest();
		private var _arrayCollectionTest: ArrayCollectionTest = new ArrayCollectionTest();
		private var _objectProxyTest	: ObjectProxyTest = new ObjectProxyTest();
		private var _byteArrayTest		: ByteArrayTest = new ByteArrayTest();
		private var _unsupportedTest	: UnsupportedTest = new UnsupportedTest();
		
		/**
		 * @return Test values.
		 */		
		public function get items(): Array
		{
			return _items;
		}
		
		/**
		 * @return Number of AMF0 tests.
		 */		
		public function get AMF0COUNT(): Number
		{
			return _amf0count;
		}
		
		/**
		 * @param val Number of AMF0 tests.
		 */		
		public function set AMF0COUNT(val:Number):void
		{
			_amf0count = val;
		}
		
		/**
		 * @param selection
		 * @param test
		 */		
		private function addTest(selection:TestSelection, test:BaseTest):void 
		{
			if ( selection && selection.selected )
			{
				var tests:Array = test.tests;
				for (var s:int=0;s<tests.length;s++)
				{
					_items.push(tests[s]);
				}
			}
		}
		
		/**
		 * @param tests
		 */				
		public function EchoTestData( tests:Array )
		{
			_items = new Array();
			
			// AMF0 specific tests below
			
			// null
			addTest(TestSelection(tests[0]), _nullTest);
			// undefined
			addTest(TestSelection(tests[1]), _undefinedTest);
			// Boolean
			addTest(TestSelection(tests[2]),  _booleanTest);
			// String
			addTest(TestSelection(tests[3]), _stringTest);
			// Number
			addTest(TestSelection(tests[4]), _numberTest);
			// Array
			addTest(TestSelection(tests[5]), _arrayTest);
			// Object
			addTest(TestSelection(tests[6]), _objectTest);
			// Date
			addTest(TestSelection(tests[7]), _dateTest);
			// XML for ActionScript 1.0 and 2.0
			addTest(TestSelection(tests[8]), _xmlDocumentTest);
			// Custom class
			addTest(TestSelection(tests[9]), _customClassTest);
			// Remote class
			addTest(TestSelection(tests[10]), _remoteClassTest);
			
			_amf0count = _items.length;
			
			// AMF3 specific tests below
			
			// XML top-level class for ActionScript 3.0
			addTest(TestSelection(tests[11]), _xmlTest);
			// Externalizable
			addTest(TestSelection(tests[12]), _externalizableTest);
			// ArrayCollection
			addTest(TestSelection(tests[13]), _arrayCollectionTest);
			// ObjectProxy
			addTest(TestSelection(tests[14]), _objectProxyTest);
			// ByteArray
			addTest(TestSelection(tests[15]), _byteArrayTest);
			// Unsupported
			addTest(TestSelection(tests[16]), _unsupportedTest);
		}
		
	}
}
