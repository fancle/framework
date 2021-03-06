package org.flexlite.domUtils
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import org.flexlite.domUI.collections.XMLCollection;
	import org.flexlite.domUI.components.Group;
	import org.flexlite.domUI.components.Label;
	import org.flexlite.domUI.components.RadioButton;
	import org.flexlite.domUI.components.RadioButtonGroup;
	import org.flexlite.domUI.components.TitleWindow;
	import org.flexlite.domUI.components.ToggleButton;
	import org.flexlite.domUI.components.Tree;
	import org.flexlite.domUI.events.TreeEvent;
	import org.flexlite.domUI.events.UIEvent;
	import org.flexlite.domUI.skins.vector.HScrollBarSkin;
	import org.flexlite.domUI.skins.vector.ListSkin;
	import org.flexlite.domUI.skins.vector.RadioButtonSkin;
	import org.flexlite.domUI.skins.vector.TitleWindowSkin;
	import org.flexlite.domUI.skins.vector.ToggleButtonSkin;
	import org.flexlite.domUI.skins.vector.TreeItemRendererSkin;
	import org.flexlite.domUI.skins.vector.VScrollBarSkin;
	
	
	/**
	 * 运行时显示列表调试工具。
	 * 快捷键：F11开启或关闭调试;F12开启或结束选择;F2复制选中的属性名;F3复制选中属性值;
	 * F5:最大化或还原属性窗口;
	 * @author DOM
	 */
	public class Debugger extends Group
	{
		/**
		 * 初始化调试工具
		 * @param stage 舞台引用
		 */		
		public static function initialize(stage:Stage):void
		{
			if(!stage)
				return;
			new Debugger(stage);
		}
		/**
		 * 构造函数
		 */		
		public function Debugger(stage:Stage)
		{
			super();
			mouseEnabled = false;
			mouseEnabledWhereTransparent = false;
			appStage = stage;
			visible = false;
			appStage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
			
			init();
		}
		
		private var window:TitleWindow = new TitleWindow();
		private var xLabel:Label = new Label();
		private var yLabel:Label = new Label();
		private var widthLabel:Label = new Label();
		private var heightLabel:Label = new Label();
		private var nameLabel:Label = new Label();
		private var selectBtn:ToggleButton = new ToggleButton();
		private var selectMode:RadioButtonGroup = new RadioButtonGroup();
		private var infoTree:Tree = new Tree();
		/**
		 * 初始化
		 */		
		private function init():void
		{
			window.skinName = TitleWindowSkin;
			window.isPopUp = true;
			window.showCloseButton = false;
			window.width = 250;
			window.title = "控制面板";
			var infoGroup:Group = new Group();
			nameLabel.text = "";
			xLabel.y = 18;
			xLabel.text = "x:";
			yLabel.y = 36;
			yLabel.text = "y:";
			widthLabel.y = 54;
			widthLabel.text = "width:";
			heightLabel.y = 72;
			heightLabel.text = "height:";
			infoGroup.y = 30;
			infoGroup.addElement(nameLabel);
			infoGroup.addElement(xLabel);
			infoGroup.addElement(yLabel);
			infoGroup.addElement(widthLabel);
			infoGroup.addElement(heightLabel);
			window.addElement(infoGroup);
			window.addEventListener(UIEvent.CREATION_COMPLETE,onWindowComp);
			selectBtn.label = "开启选择";
			selectBtn.y = 5;
			selectBtn.x = 3;
			selectBtn.selected = true;
			selectBtn.skinName = ToggleButtonSkin;
			selectBtn.addEventListener(Event.CHANGE,onSelectedChange);
			window.addElement(selectBtn);
			var label:Label = new Label();
			label.text = "模式:";
			label.y = 8;
			label.x = 75;
			window.addElement(label);
			var displayRadio:RadioButton = new RadioButton();
			displayRadio.group = selectMode;
			displayRadio.skinName = RadioButtonSkin;
			displayRadio.x = 110;
			displayRadio.y = 5;
			displayRadio.selected = true;
			displayRadio.label = "显示列表";
			window.addElement(displayRadio);
			var mouseRadio:RadioButton = new RadioButton();
			mouseRadio.skinName = RadioButtonSkin;
			mouseRadio.group = selectMode;
			mouseRadio.x = 180;
			mouseRadio.y = 5;
			mouseRadio.label = "鼠标事件";
			window.addElement(mouseRadio);
			selectMode.addEventListener(Event.CHANGE,onSelectModeChange);
			infoTree.skinName = ListSkin;
			infoTree.left = 0;
			infoTree.right = 0;
			infoTree.top = 120;
			infoTree.bottom = 0;
			infoTree.minHeight = 200;
			infoTree.dataProvider = infoDp;
			infoTree.labelFunction = labelFunc;
			infoTree.addEventListener(TreeEvent.ITEM_OPENING,onTreeOpening);
			infoTree.addEventListener(UIEvent.CREATION_COMPLETE,onTreeComp);
			window.addElement(infoTree);
			addElement(window);
		}
		/**
		 * 选择模式发生改变
		 */		
		private function onSelectModeChange(event:Event):void
		{
			if(selectMode.selectedValue=="鼠标事件")
			{
				appStage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
				appStage.addEventListener(MouseEvent.MOUSE_OVER,onMouseOver);
				appStage.addEventListener(MouseEvent.MOUSE_OUT,onMouseOut);
			}
			else
			{
				appStage.removeEventListener(MouseEvent.MOUSE_OVER,onMouseOver);
				appStage.removeEventListener(MouseEvent.MOUSE_OUT,onMouseOut);
				appStage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
			}
			selectBtn.selected = true;
			onSelectedChange();
		}
		/**
		 * 树列表创建完成
		 */		
		private function onTreeComp(event:UIEvent):void
		{
			infoTree.removeEventListener(UIEvent.CREATION_COMPLETE,onTreeComp);
			infoTree.dataGroup.itemRendererSkinName = TreeItemRendererSkin;
			(infoTree.skin as ListSkin).scroller.verticalScrollBar.skinName = VScrollBarSkin;
			(infoTree.skin as ListSkin).scroller.horizontalScrollBar.skinName = HScrollBarSkin;
		}
		/**
		 * 即将打开树的一个节点,生成子节点内容。
		 */		
		private function onTreeOpening(event:TreeEvent):void
		{
			if(!event.opening)
				return;
			var item:XML = event.item as XML;
			if(item.children().length()==1&&
				item.children()[0].localName()=="child")
			{
				var keys:Array = [String(item.@key)];
				var parent:XML = item.parent();
				while(parent&&parent.parent())
				{
					if(parent.localName()!="others")
						keys.push(String(parent.@key));
					parent = parent.parent();
				}
				var target:Object = currentTarget;
				try
				{
					while(keys.length>0)
					{
						var key:String = keys.pop();
						if(key.substr(0,8)=="children")
						{
							var index:int = int(key.substring(9,key.length-1));
							target = DisplayObjectContainer(target).getChildAt(index);
						}
						else
						{
							if(key.charAt(0)=="["&&key.charAt(key.length-1)=="]")
							{
								index = int(key.substring(9,key.length-1));
								target = target[index];
							}
							else
							{
								target = target[key];
							}
						}
					}
				}
				catch(e:Error)
				{
					return;
				}
				item.setChildren(describe(target).children());
			}
		}
		/**
		 * 树列表项显示文本格式化函数
		 */		
		private function labelFunc(item:Object):String
		{
			if(item.hasOwnProperty("@value"))
				return item.@key+" : "+item.@value;
			return item.@key;
		}

		private function onSelectedChange(event:Event=null):void
		{
			if(selectBtn.selected)
			{
				currentTarget = null;
				mouseEnabled = false;
				infoDp.source = null;
				invalidateDisplayList();
			}
		}
		/**
		 * 窗口创建完成
		 */		
		private function onWindowComp(event:Event):void
		{
			window.removeEventListener(UIEvent.CREATION_COMPLETE,onWindowComp);
			window.moveArea.doubleClickEnabled = true;
			window.moveArea.addEventListener(MouseEvent.DOUBLE_CLICK,onWindowDoubleClick);
		}
		
		private var oldX:Number;
		private var oldY:Number;
		private var oldWidth:Number;
		private var oldHeight:Number;
		/**
		 * 双击窗口放大或还原
		 */		
		private function onWindowDoubleClick(event:MouseEvent=null):void
		{
			window.isPopUp = !window.isPopUp;
			if(window.isPopUp)
			{
				window.x = oldX;
				window.y = oldY;
				window.width = oldWidth;
				window.height = oldHeight;
			}
			else
			{
				oldX = window.x;
				oldY = window.y;
				oldWidth = window.width;
				oldHeight = window.height;
				window.x = 0;
				window.y = 0;
				window.width = width;
				window.height = height;
			}
		}
		/**
		 * 舞台引用
		 */		
		private var appStage:Stage;
		/**
		 * 键盘事件
		 */		
		private function onKeyDown(event:KeyboardEvent):void
		{
			if(event.keyCode==Keyboard.F11)
			{
				visible = !visible;
				if(visible)
				{
					show();
				}
				else
				{
					close();
				}
			}
			if(!parent)
				return;
			if(event.keyCode==Keyboard.F5)
			{
				onWindowDoubleClick();
			}
			else if(!currentTarget)
			{
				return;
			}
			else if(event.keyCode==Keyboard.F2)
			{
				var item:XML = infoTree.selectedItem as XML;
				if(item)
				{
					System.setClipboard(String(item.@key));
				}
			}
			else if(event.keyCode==Keyboard.F3)
			{
				item = infoTree.selectedItem as XML;
				if(item)
				{
					System.setClipboard(String(item.@value));
				}
			}
			else if(event.keyCode==Keyboard.F12)
			{
				if(selectBtn.selected)
				{
					selectBtn.selected = false;
					mouseEnabled = true;
					infoDp.source = describe(currentTarget);
				}
				else
				{
					selectBtn.selected = true;
					onSelectedChange();
					mouseMoved = true;
					invalidateProperties();
				}
			}
		}
		
		/**
		 * 显示
		 */		
		private function show():void
		{
			var list:Array = appStage.getObjectsUnderPoint(new Point(appStage.mouseX,appStage.mouseY));
			if(list.length>0)
			{
				currentTarget = list[list.length-1];
			}
			appStage.addChild(this);
			invalidateDisplayList();
			appStage.addEventListener(Event.ADDED,onAdded);
			appStage.addEventListener(Event.RESIZE,onResize);
			appStage.addEventListener(FullScreenEvent.FULL_SCREEN,onResize);
			if(selectMode.selectedValue=="鼠标事件")
			{
				appStage.addEventListener(MouseEvent.MOUSE_OVER,onMouseOver);
				appStage.addEventListener(MouseEvent.MOUSE_OUT,onMouseOut);
			}
			else
			{
				appStage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
			}
			appStage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
			onResize();
			window.x = width-window.width;
		}
		
		/**
		 * 关闭
		 */		
		private function close():void
		{
			if(parent)
				parent.removeChild(this);
			currentTarget = null;
			infoDp.source = null;
			selectBtn.selected = true;
			mouseEnabled = false;
			appStage.removeEventListener(Event.ADDED,onAdded);
			appStage.removeEventListener(Event.RESIZE,onResize);
			appStage.removeEventListener(FullScreenEvent.FULL_SCREEN,onResize);
			appStage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
			appStage.removeEventListener(MouseEvent.MOUSE_OVER,onMouseOver);
			appStage.removeEventListener(MouseEvent.MOUSE_OUT,onMouseOut);
			appStage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
		}
		/**
		 * stage子项发生改变
		 */		
		private function onAdded(event:Event):void
		{
			if(parent.getChildIndex(this)!=parent.numChildren-1)
				parent.addChild(this);
		}
		
		/**
		 * 舞台尺寸改变
		 */		
		private function onResize(event:Event=null):void
		{
			width = stage.stageWidth;
			height = stage.stageHeight;
			if(!window.isPopUp)
			{
				window.width = width;
				window.height = height;
			}
			window.maxHeight = height;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			if(mouseMoved)
			{
				mouseMoved = false;
				var target:DisplayObject;
				if(!window.hitTestPoint(appStage.mouseX,appStage.mouseY)
					&&appStage.numChildren>1)
				{
					for(var i:int=appStage.numChildren-2;i>=0;i--)
					{
						var dp:DisplayObject = appStage.getChildAt(i);
						if(!dp.hitTestPoint(appStage.mouseX,appStage.mouseY,true))
							continue;
						target = dp;
						if(dp is DisplayObjectContainer)
						{
							var list:Array = DisplayObjectContainer(dp).getObjectsUnderPoint(new Point(appStage.mouseX,appStage.mouseY));
							if(list.length>0)
							{
								target = list[list.length-1];
							}
						}
						if(target)
							break;
					}
					
					
					
				}
				
				if(currentTarget != target)
				{
					currentTarget = target;
					invalidateDisplayList();
				}
				
			}
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w,h);
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0,0.2);
			g.drawRect(0,0,w,h);
			if(currentTarget)
			{
				var pos:Point = currentTarget.localToGlobal(new Point());
				xLabel.text = "x: "+pos.x;
				yLabel.text = "y: "+pos.y;
				widthLabel.text = "width: "+currentTarget.width;
				heightLabel.text = "height: "+currentTarget.height;
				var className:String = getQualifiedClassName(currentTarget);
				nameLabel.text = "target: ";
				if(className.indexOf("::")!=-1)
					nameLabel.text += className.split("::")[1];
				else
					nameLabel.text += className;
				nameLabel.text += "#"+currentTarget.name;
				g.drawRect(pos.x,pos.y,currentTarget.width,currentTarget.height);
				g.endFill();
				g.beginFill(0x009aff,0);
				g.lineStyle(1,0xff0000);
				g.drawRect(pos.x,pos.y,currentTarget.width,currentTarget.height);
			}
			else
			{
				nameLabel.text = "target: ";
				xLabel.text = "x: ";
				yLabel.text = "y: ";
				widthLabel.text = "width: ";
				heightLabel.text = "height: ";
				
			}
			g.endFill();
		}
		/**
		 * 当前鼠标下的对象
		 */		
		private var currentTarget:DisplayObject;
		/**
		 * 鼠标移动过的标志
		 */		
		private var mouseMoved:Boolean = false;
		/**
		 * 鼠标移动
		 */		
		private function onMouseMove(event:MouseEvent):void
		{
			if(mouseMoved||!selectBtn.selected)
				return;
			mouseMoved = true;
			invalidateProperties();
		}	
		
		/**
		 * 鼠标经过
		 */		
		private function onMouseOver(event:MouseEvent):void
		{
			if(!selectBtn.selected||contains(event.target as DisplayObject))
				return;
			currentTarget = event.target as DisplayObject;
			
			invalidateDisplayList();
		}
		
		private function onMouseOut(event:MouseEvent):void
		{
			if(!selectBtn.selected||contains(event.target as DisplayObject))
				return;
			currentTarget = null;
			invalidateDisplayList();
		}
		
		private var infoDp:XMLCollection = new XMLCollection();
		private function onMouseDown(event:MouseEvent):void
		{
			if(!selectBtn.selected)
				return;
			if(currentTarget)
			{
				selectBtn.selected = false;
				mouseEnabled = true;
				infoDp.source = describe(currentTarget);
			}
		}
		private function describe(target:Object):XML
		{
			var xml:XML = <root/>;
			var items:Array = [];
			try
			{
				var type:String = getQualifiedClassName(target);
			}
			catch(e:Error){}
			if(type=="Array")
			{
				var length:int = (target as Array).length;
				for(var i:int=0;i<length;i++)
				{
					var childValue:* = target[i];
					item = <item></item>;
					item.@key = "["+i+"]";
					try
					{
						type = getQualifiedClassName(childValue);
						if(childValue===null||childValue===undefined||
							basicTypes.indexOf(type)!=-1)
							item.@value = childValue;
						else
						{
							item.@value = "["+type+"]";
							item.appendChild(<child/>);
						}
					}
					catch(e:Error){}
					xml.appendChild(item);
				}
				return xml;
			}
			else if(type=="Object")
			{
				for(var key:String in target)
				{
					item = <item/>;
					item.@key = key;
					try
					{
						type = getQualifiedClassName(target[key]);
						if(target[key]===null||target[key]===undefined||
							basicTypes.indexOf(type)!=-1)
							item.@value = target[key];
						else
						{
							item.@value = "["+type+"]";
							item.appendChild(<child/>);
						}
					}
					catch(e:Error){}
					items.push(item);
				}
				items.sortOn("@key");
				while(items.length>0)
				{
					xml.appendChild(items.shift());
				}
				return xml;
			}
			var info:XML = describeType(target);
			var others:Array = [];
			var children:Array = [];
			var childXMLList:XMLList = info.variable+info.accessor;
			for each(var node:XML in childXMLList)
			{
				if(node.@access=="writeonly")
					continue;
				var item:XML = <item/>;
				key = node.@name.toString();
				if(key=="stage")
					continue;
				item.@key = key;
				if(layoutProps.indexOf(key)==-1)
					others.push(item);
				else
					items.push(item);
				try
				{
					type = getQualifiedClassName(target[key]);
				}
				catch(e:Error){}
				try
				{
					if(target[key]===null||target[key]===undefined||
						basicTypes.indexOf(type)!=-1)
						item.@value = target[key];
					else
					{
						item.@value = "["+type+"]";
						item.appendChild(<child/>);
					}
				}
				catch(e:Error){}
			}
			if(target is DisplayObjectContainer)
			{
				var dc:DisplayObjectContainer = DisplayObjectContainer(target);
				var numChildren:int = dc.numChildren;
				for(i=0;i<numChildren;i++)
				{
					var child:DisplayObject = dc.getChildAt(i);
					item = <item><child/></item>;
					item.@key = "children["+i+"]";
					try
					{
						item.@value = "["+getQualifiedClassName(child)+"]";
					}
					catch(e:Error){}
					children.push(item);
				}
			}
			if(children.length>0)
			{
				while(children.length>0)
				{
					xml.appendChild(children.shift());
				}
			}
			items.sortOn("@key");
			others.sortOn("@key");
			if(items.length==0)
			{
				items = others;
				others = [];
			}
			else if(!(target is DisplayObject))
			{
				items = items.concat(others);
				others = [];
			}
			if(others.length>0)
			{
				var other:XML = <others key="其他属性"/>;
				while(others.length>0)
				{
					other.appendChild(others.shift());
				}
				xml.appendChild(other);
			}
			while(items.length>0)
			{
				xml.appendChild(items.shift());
			}
			
			return xml;
		}
		
		private var layoutProps:Vector.<String> = 
			new <String>["x","y","width","height","measuredWidth","measuredHeight",
			"layoutBoundsWidth","layoutBoundsHeight","preferredWidth","preferredHeight",
			"left","right","top","bottom","percentWidth","percentHeight","verticalCenter",
			"horizontalCenter","explicitWidth","explicitHeight","paddingTop","paddingLeft",
			"paddingRight","paddingBottom","includeInLayout","preferredX","preferredY",
			"layoutBoundsX","layoutBoundsY","scaleX","scaleY","maxWidth","minWidth",
			"maxHeight","minHeight","visible","alpha","parent","skinName","skin","enabled",
			"initialized","isPopUp","mouseEnabled","mouseChildren","focusEnabled"];
		/**
		 * 基本数据类型列表
		 */		
		private var basicTypes:Vector.<String> = 
			new <String>["Number","int","String","Boolean","uint"];
	}
}