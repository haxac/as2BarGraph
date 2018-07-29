//********************************************************************************************
//*
//*   disp bar graph
//*
//********************************************************************************************
import flash.geom.Matrix;
import mx.core.UIObject;
import mx.controls.Label;

/**
 * 棒グラフを表示します。
 * TODO 縦の基準値を表示
 * TODO マウスカーソルを乗せたときに数値表示
 * TODO 伸びるアニメーション？
 */
class as2BarGraph {
	private var mc_graph:MovieClip;		//グラフを表示する空のムービークリップ
	private var display_x:Number;		//グラフ表示位置X
	private var display_y:Number;		//グラフ表示位置Y
	private var display_width:Number;	//グラフ表示範囲横幅
	private var display_height:Number;	//グラフ表示範囲縦
	private var goal:Number;			//目標値（赤線を引きます）
	private var graphData:Array;		//グラフ表示用データの配列
	private var bar_count:Number;		//棒の数
	private var max_bar_height:Number;	//棒の最大の長さ
	
	private var background_color:Number = 0xFFFFFF;	//グラフ描画領域の背景色
	private var bar_color:Number =  0x0000FF;		//棒の色
	private var line_color:Number = 0x000000;		//線の色
	private var gline_color:Number = 0xAAAAAA;		//グレーの横線の色
	private var goal_color:Number = 0xFF6666;		//目標線の色
	
	private var columnDivideCount:Number = 6		//横に6分割
	
	private var nextDepth:Number;					//現在のレイヤの深さ
	
	private var rowMemori = [1, 5, 10, 50, 100, 500, 1000, 5000, 10000];	//縦軸目盛り（×10,000）
	
	private var startValue:Number;					//グラフ最下部の値
	private var limitValue:Number;					//グラフ最上部の値
	private var valuePerMemori:Number;				//目盛り辺りの値
	
	private var labelText:String;						//ラベル
	private var labelSize:Number;						//ラベルのサイズ
	
	private var barValueField:TextField;			//棒の値表示テキストフィールド

	/**
	 * 新しい棒グラフを作成します。
	 * _display_x      グラフ表示位置X
	 * _display_y      グラフ表示位置Y
	 * _display_width  グラフ表示範囲横幅
	 * _display_height グラフ表示範囲縦
	 * _mokuhyou       目標値（赤線を引きます）
	 * _graphData      グラフ表示用データの配列
	 */
	public function as2BarGraph(_mc_graph:MovieClip, _display_x:Number
		, _display_y:Number, _display_width:Number, _display_height:Number
		, _mokuhyou:Number, _graphData:Array, _labelText:String, _labelSize:Number) {

		this.mc_graph = _mc_graph;
		this.display_x = _display_x;
		this.display_y = _display_y;
		this.display_width = _display_width;
		this.display_height = _display_height;
		this.goal = _mokuhyou;
		this.graphData = _graphData;
		this.bar_count = this.graphData.length;
		this.nextDepth = this.mc_graph.getDepth();
		this.max_bar_height = this.display_height - getColumnLineHeight();
		this.labelText = _labelText;
		this.labelSize = _labelSize;
		//グラフ描画
		makeGraphDisplay();			//背景
		drowColumnGrayLine();		//グレーの横線
		setvaluePerMemori();		//グラフ目盛り辺りの値
		drowGoalLine();				//目標の横線
		drowUnderLine();			//下の黒い横線
		drowLeftLine();				//左の黒い縦線
		drowBar();					//棒
		drowRowDivideLine();		//下の黒い目盛りの線
		drowColumnDivideLine();		//横の黒い目盛りの線
		showRowLabel();				//下の日付表示
		showColumnLabel();			//左の数値ラベル
	}
	
	//各棒の上に実際の数値を表示します。
	public function showBarValue() {
		var barSpaceWidth = getBarSpaceWidth();
		for(var i = 0; i < this.graphData.length; i++) {
		
			var w = barSpaceWidth;
			var h = 20;
		
			var d = this.graphData.getItemAt(i);
			var x = barSpaceWidth + (barSpaceWidth * i);
			var y = this.display_height - (d["barLength"] + this.display_height/6 + h/1.5);
			var t = d["disp_data"];
		
			this.barValueField = this.mc_graph.createTextField("barValueField", this.mc_graph.getNextHighestDepth()
			, x, y, w, h);
			this.barValueField.text = t;
			
			//フォントサイズ小さめのメイリオにする
			var myformat:TextFormat = new TextFormat();
			myformat.size = 8;
			myformat.font = "メイリオ";
			myformat.align = "center";
			this.barValueField.setTextFormat(myformat)

		}
	}

	//グラフ表示領域を作成します。
	private function makeGraphDisplay() {
		this.mc_graph._x = this.display_x;
		this.mc_graph._y = this.display_y;
		var w = this.display_width - 10;
		var h = this.display_height - 10;
		drawRectangle(this.mc_graph, w, h, background_color, 100);
		
	}

	//下の横先を引きます。
	private function drowUnderLine() {
		var margin = getBarLeftSpace();	//左にくっつけない
		var uLine:MovieClip = this.mc_graph.createEmptyMovieClip("uLine", getNextDepth());
		uLine.lineStyle(1, this.line_color, 100);
		uLine.moveTo(getBarSpaceWidth(), this.display_height - getColumnLineHeight());
		uLine.lineTo(this.display_width - margin, this.display_height - getColumnLineHeight());
	}

	//左の縦線を引きます。
	private function drowLeftLine() {
		var margin = getBarLeftSpace() * 2;	//上にくっつけない
		var lLine:MovieClip = this.mc_graph.createEmptyMovieClip("lLine", getNextDepth());
		lLine.lineStyle(1, this.line_color, 100);
		lLine.moveTo(getBarSpaceWidth(), margin);
		lLine.lineTo(getBarSpaceWidth(), display_height - getColumnLineHeight());
	}

	//下の区切り線を引きます。
	private function drowRowDivideLine() {
		var len = getBarLeftSpace();	//棒の左余白と同じ長さ
		
		//棒の数+1本
		var y_start = display_height - getColumnLineHeight();
		for(var i = 0; i <= bar_count; i++) {
			var dLine:MovieClip = this.mc_graph.createEmptyMovieClip("dLine", getNextDepth());
			var x = getBarSpaceWidth() * (i + 1);
			dLine.lineStyle(1, this.line_color, 100);
			dLine.moveTo(x, y_start);
			dLine.lineTo(x, y_start + len);
		}
		
		//右端の1本
		var dLine:MovieClip = this.mc_graph.createEmptyMovieClip("dLine", getNextDepth());
		var margin = getBarLeftSpace();
		dLine.lineStyle(1, this.line_color, 100);
		dLine.moveTo(display_width - margin, y_start);
		dLine.lineTo(display_width - margin, y_start + len);
	}

	//横の区切り線を引きます。
	private function drowColumnDivideLine() {
		var len = getBarLeftSpace();	//棒の左余白と同じ長さ
		var x_start = getBarSpaceWidth() - len;
		var y = this.display_height - getColumnLineHeight();
		
		for(var i = 0; i < columnDivideCount - 1; i++) {
			var y = this.display_height - getColumnLineHeight() * (i + 1);
			var cLine:MovieClip = this.mc_graph.createEmptyMovieClip("cLine", getNextDepth());
			cLine.lineStyle(1, this.line_color, 100);
			cLine.moveTo(x_start, y);
			cLine.lineTo(x_start + len, y);
		}
	}

	//横に薄いグレーの線を引きます。
	//※破線が普通に引けないため
	private function drowColumnGrayLine() {
		var len = this.display_width - getBarSpaceWidth() - getBarLeftSpace();
		var x_offset = getBarSpaceWidth();
		var y_offset = display_height - getColumnLineHeight() * 1.5;

		for(var i = 0; i < columnDivideCount - 1; i++) {
			var gLine:MovieClip = this.mc_graph.createEmptyMovieClip("gLine", getNextDepth());
			var y = y_offset - i * getColumnLineHeight();
			gLine.lineStyle(1, this.gline_color, 100);
			gLine.moveTo(x_offset, y);
			gLine.lineTo(x_offset + len, y);
		}
	}

	//棒を書きます。
	private function drowBar() {
	
		var offset = getBarSpaceWidth();

		for(var i = 0; i < this.graphData.length; i++) {
			var bar:MovieClip = this.mc_graph.createEmptyMovieClip("bar", getNextDepth());
			bar._x = offset + getBarLeftSpace();
			bar._y = this.display_height - getColumnLineHeight();

			var barLength = (this.graphData.getItemAt(i)["data"] - this.startValue) * calcDiscount();
			if(barLength < 0) {
				barLength = 0;
			}
			this.graphData.getItemAt(i)["barLength"] = barLength;
			if(barLength > this.max_bar_height) {
				barLength = this.max_bar_height;	//はみ出し禁止
			}

			drawRectangleByGradient(bar, getBarWidth()
				, -1 * barLength, bar_color, 100);
			offset += getBarSpaceWidth();
		}
	}

	//ラベルを横に張ります。
	private function showRowLabel() {
		var x_offset = getBarSpaceWidth();
		var y = display_height - getColumnLineHeight();

		for(var i = 0; i < this.graphData.length; i++) {
			var rowLabel = this.mc_graph.createTextField("rowLabel", getNextDepth(), x_offset, y, getBarSpaceWidth(), getColumnLineHeight());
			rowLabel.text = this.graphData.getItemAt(i)["label"];
			x_offset += getBarSpaceWidth();

			//フォントサイズ小さめのメイリオにする
			var myformat:TextFormat = new TextFormat();
			myformat.size = 9;
			myformat.align = "center";
			myformat.font = "メイリオ";
			rowLabel.setTextFormat(myformat)

		}
	}
	
	//ラベルを縦に張ります。
	private function showColumnLabel() {
	
		var x_offset = getBarLeftSpace() / 2;
		var maxGraphHeight = this.display_height - getColumnLineHeight();
		var y_offset = 0;
		var memoriValue = 0;

		for(var i = 0; i < (this.columnDivideCount - 1) * 2; i+=2) {
			memoriValue = this.valuePerMemori * (i) * 10000 + this.startValue;
			y_offset = maxGraphHeight - ((memoriValue - this.startValue) * calcDiscount()) - 8;
			var colLabel = this.mc_graph.createTextField("colLabel", getNextDepth(), x_offset - getBarLeftSpace() - 8, y_offset, getBarSpaceWidth() + 5, getColumnLineHeight());
			colLabel.text = _global.gf_comma_format(true, (memoriValue / 10000));
			
			//フォントサイズ小さめのメイリオにする
			var myformat:TextFormat = new TextFormat();
			myformat.size = 9;
			myformat.align = "right";
			myformat.font = "メイリオ";
			colLabel.setTextFormat(myformat)

		}
		
		memoriValue = this.valuePerMemori * (i) * 10000 + this.startValue;
		y_offset = maxGraphHeight - ((memoriValue - this.startValue) * calcDiscount());
		var colLabel = this.mc_graph.createTextField("colLabel", getNextDepth(), x_offset, y_offset, getBarSpaceWidth()*4, getColumnLineHeight());
		colLabel.text = this.labelText;

		//指定のフォントサイズのメイリオにする
		var myformat:TextFormat = new TextFormat();
		myformat.size = this.labelSize;
		myformat.font = "メイリオ";
		colLabel.setTextFormat(myformat)
		
	}

	//目標の赤線を引きます。
	private function drowGoalLine() {
		if(this.goal == 0 || this.goal == undefined) {
			return;
		}
		if(this.goal > this.limitValue || this.goal < this.startValue) {
			//目標はみでるので表示しない
			return;
		}
		var len = this.display_width - getBarSpaceWidth() - getBarLeftSpace();
		var x_offset = getBarSpaceWidth();
		
		var maxGraphHeight = this.display_height - getColumnLineHeight();
		var goalHeight = maxGraphHeight - (this.goal - this.startValue) * calcDiscount();
		
		var goalLine:MovieClip = this.mc_graph.createEmptyMovieClip("goalLine", getNextDepth());
		goalLine.lineStyle(1, this.goal_color, 100);
		goalLine.moveTo(x_offset, goalHeight);
		goalLine.lineTo(x_offset + len, goalHeight);
	}

	//棒の高さを実際の数値の何割で表現すればよいか計算します。
	//グラフの最大値が最上部の横線と等しくなるように調整します。
	private function calcDiscount() : Number {
		var maxLength = 0;
		var minLength = 0;
		for(var i = 0; i < this.graphData.length; i++) {
			if(this.graphData.getItemAt(i)["data"] != 0) {
				if(maxLength < this.graphData.getItemAt(i)["data"]) {
					maxLength = this.graphData.getItemAt(i)["data"];
				}
				if(minLength > this.graphData.getItemAt(i)["data"]) {
					minLength = this.graphData.getItemAt(i)["data"];
				}
			}
		}
		if(maxLength < this.goal) {
			maxLength = this.goal;
		}
		if(minLength > this.goal) {
			minLength = this.goal;
		}
		var maxGraphHeight = this.display_height - getColumnLineHeight();
		return maxGraphHeight / (this.limitValue - this.startValue);
		
	}

	/**
	 * 領域の幅と棒の数より、棒1本あたりに必要な幅を算出します。
	 */
	private function getBarSpaceWidth() : Number {
		var bunkatu:Number = this.bar_count + 1.5;
		var w = Math.floor(this.display_width / bunkatu);
		return w;
	}

	/**
	 * 横軸の高さを返します。
	 * 横軸の数はとりえあずフィールドで設定
	 */
	private function getColumnLineHeight() : Number {
		return this.display_height / columnDivideCount;
	}

	/**
	 * 棒の左余白の幅を返します。
	 */
	private function getBarLeftSpace() : Number {
		var s_width = getBarSpaceWidth();
		return s_width / 5;
	}

	/**
	 * 棒の幅を返します。
	 */
	private function getBarWidth() : Number {
		return getBarLeftSpace() * 3;
	}

	/**
	 * 四角を描画します。
	 * target_mc 描画するムービークリップ
	 * boxWidth  幅
	 * boxHeight 高さ
	 * fillColor 塗りつぶす色
	 * fillAlpha 塗りつぶしのアルファ
	 */
	private function drawRectangle(target_mc:MovieClip, boxWidth:Number
		, boxHeight:Number, fillColor:Number, fillAlpha:Number):Void {
		with (target_mc) {
			beginFill(fillColor, fillAlpha);
			moveTo(0, 0);
			lineTo(boxWidth, 0);
			lineTo(boxWidth, boxHeight);
			lineTo(0, boxHeight);
			lineTo(0, 0);
			endFill();
		}
	}

	/**
	 * 四角をグラデーション描画します。
	 * 色は決め打ちです。
	 * target_mc 描画するムービークリップ
	 * boxWidth  幅
	 * boxHeight 高さ
	 * fillColor 塗りつぶす色
	 * fillAlpha 塗りつぶしのアルファ
	 */
	private function drawRectangleByGradient(target_mc:MovieClip, boxWidth:Number
		, boxHeight:Number, fillColor:Number, fillAlpha:Number):Void {

		var colors=[0x0000FF, 0x6666FF, 0x0000FF];
		var alphas=[100, 100, 100];
		var rations=[0, 127, 255];
		var matrix={matrixType:"box", x:0, y:boxHeight, w:getBarWidth(), h:0, r:0};

		with (target_mc) {
			beginGradientFill("linear", colors, alphas, rations, matrix);
			moveTo(0, 0);
			lineTo(boxWidth, 0);
			lineTo(boxWidth, boxHeight);
			lineTo(0, boxHeight);
			lineTo(0, 0);
			endFill();
		}
	}
	
	//ムービークリップを作成する際の深度を返します。
	private function getNextDepth() : Number {
		return ++this.nextDepth;
	}
	
	//グラフ１目盛りあたりの値と最下部の値、最上部の値を求めます。
	private function setvaluePerMemori() {
		var maxLength = 0;	//データの最大値
		var minLength = 0;	//データの最小値
		//グラフ用データから最大値を探す
		for(var i = 0; i < this.graphData.length; i++) {
			if(maxLength < this.graphData.getItemAt(i)["data"]) {
				maxLength = this.graphData.getItemAt(i)["data"];
			}
		}
		//グラフ用データから最小値を探す
		//最小値-マージンをグラフの最下部にするので、0以外で探す。
		//0を含めるとグラフ最下部がマイナスになるため。
		minLength = maxLength;
		for(var i = 0; i < this.graphData.length; i++) {
			if(minLength > this.graphData.getItemAt(i)["data"] && this.graphData.getItemAt(i)["data"] != 0) {
				minLength = this.graphData.getItemAt(i)["data"];
			}
		}

		//全データが0の場合は、0開始、1万区切りのMAX10万固定
		var valuePerMemori = 10000;	//1目盛り辺りの数値
		var limit = 100000;			//グラフ最上値
		var defaultStartValue = 0;	//グラフ最下部
		if(maxLength == 0 && minLength == 0) {
			this.valuePerMemori = valuePerMemori;
			this.limitValue = limit;
			this.startValue = defaultStartValue;
			return;
		}

		//1目盛りあたりの値はフィールド rowMemori で指定した値のどれか
		//最小値がグラフ内に描画可能な値を探す。
		for(var i = 0; i < rowMemori.length; i++) {
			var rowValue = rowMemori[i] * 10000;
			//グラフ最上部の数値（最大値に一番近い区切り位置）
			//一番上の横線をはみ出さない高さに抑えるために、データ最大値の110%で算出する。
			limit = (maxLength * 1.1) + (rowValue - (maxLength * 1.1)%(rowValue));
			if(minLength > (limit - rowValue * 9)) {
				//最小値がグラフ内に描画可能
				valuePerMemori = rowMemori[i];

				this.valuePerMemori = valuePerMemori;
				this.limitValue = limit;
				this.startValue = this.limitValue - (this.valuePerMemori * 10 * 10000);

				break;
			}
		}
		if(this.startValue < 0) {
			//最下部の値がマイナスにならないように、最下部を0として最上部の値を調整する。
			this.startValue = 0;
			this.limitValue = this.valuePerMemori * 10 * 10000;
		}
		return;
	}
}
