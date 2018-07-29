# as2BarGraph
Chart display library for ActionScript 2.

## Description
ActionScript2で棒グラフを表示するためのクラス。
コンストラクタにMovieClip、表示位置、データ配列などを渡すとグラフ表示します。

## Requirement
* AcrionScript2.0

## Usage
```
// グラフの基となるデータ配列
var hoge:Array = new Array();
var p = 40;
for(var i = 0; i < 10; i++) {
	var objItem = new Object();
	objItem["data"] = p;
	objItem["label"] = (i +1)+ "";
	hoge.push(objItem);
	//適当にデータ作る
	if(p == 60) {
		p -= 20;
	} else {
		p+= 10;
	}
}

//グラフ表示用のMovieClip
var mcGraphDisplay:MovieClip = this.createEmptyMovieClip("mcGraphDisplay", this.getNextHighestDepth());
//コンストラクタに必要な情報を渡す
var graph:RvfBarGraph = new RvfBarGraph(mcGraphDisplay, 627, 604, 378, 144, 50, hoge);
```

