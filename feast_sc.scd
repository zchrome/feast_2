// Like this:

AtkHoa.defaultOrder;
AtkHoa.format;
AtkHoa.ordering;
AtkHoa.normalisation;
AtkHoa.formatDict;

(
Server.default.options.outDevice_("BlackHole 16ch");
Server.default.options.numOutputBusChannels_(16);
Server.default.options.memSize_(32768);

~cwd = PathName(thisProcess.nowExecutingPath).pathOnly;
~jsonFile = ~cwd ++ "data/map_uuid.json";
~soundObjects =  ~jsonFile.parseJSONFile;
//Server.default.options.outDevice_("MADIface Pro (79251081)")

Require("feast_functions");

MIDIClient.init;
MIDIIn.connectAll;

// Set up envvar somwhere sensible...
~cursor = Point(0, 0);
// Define the width and height of the "viewport"
~wp = [800, 800];
// Conditionally test if a coordinate is within bounds
)

(
var xy = [1280, 1024];
~mainWindow !? { ~mainWindow.close; };

~mainWindow = Window.new("MapFace Culling",
	bounds: Rect(0,0, *xy),
	resizable: false
).acceptsMouseOver_(true);

// Iterate over living...

~mapView = UserView(~mainWindow, Rect(240, 112, 800, 800)).background_(Color.white);
// Translated coordinate system:
// This is the correct way of drawing "living objects":

~mapView.drawFunc_({
	|objects|
	var center;
	// Translate the canvas so that 400, 400 is 0,0;

	Pen.translate(400, 400); // Half
	Pen.scale(1, -1); // Correct for "polar"
	center = Point(0, 0);
	Pen.addArc(center, 30, 0, 2pi);
	Pen.addRect(Rect(-400, -400, 800, 800));
	Pen.stroke;

	~livingObjects.do({
		|obj, index|
		var x = obj[0];
		var y = obj[1];
		var objPolar;
		var objPoint = Point(x - ~cursor.x, y - ~cursor.y);

		Pen.line(objPoint, 0@0);
		//		Pen.line(objPoint.x@400, objPoint.x@400.neg);
		// Pen.line(400@objPoint.y, 400.neg@objPoint.y);
		Pen.stroke;
		Pen.addArc(objPoint, 10, 0, 2pi);
		Pen.fill;

		// Lets try to overlay another visualisation just for funs
		// We can get the theta with atan2!

		objPolar = Polar(200, objPoint.theta).asCartesian;

		Pen.addArc(objPolar.x@objPolar.y, (10 /(objPoint.rho)*200), 0, 2pi);
		Pen.stroke;

	});

	//	Pen.addRect(Rect(200.neg - ~cursor.x, 200.neg - ~cursor.x, 400, 400));

	}).animate_(true);

~sliderAccelX = Slider(~mainWindow, Rect(240, 800 + 112, 800, 25))
.action_({
	|slider|
	~accel.x = slider.value.range(-1, 1);
}).value_(0.5)
.thumbSize_(40)
.orientation_(\horizontal);

~sliderAccelY = Slider(~mainWindow, Rect(215, 112, 25, 800))
.action_({
	|slider|
	~accel.y = slider.value.range(-1, 1);
})
.thumbSize_(40)
.value_(0.5);


~sliderTime = Slider(~mainWindow, Rect(1100, 112, 25, 800))
.action_({
	|slider|
	~timeScale = slider.value.range(0, 2);
})
.knobColor_(Color.black)
.background_(Color.black)
.thumbSize_(40)
.value_(0);

~sliderZoom = Slider(~mainWindow, Rect(1100+30, 112, 25, 800))
.action_({
	|slider|
	~zoomFactor = slider.value.range(1, 4);
})
.knobColor_(Color.black)
.background_(Color.cyan)
.thumbSize_(40)
.value_(0);

~sliderSubsVol = Slider(~mainWindow, Rect(1100+90, 112, 25, 800))
.action_({
	|slider|
	~reaper.sendMsg("/track/4/volume", slider.value.range(0, 0.9));
})
.knobColor_(Color.black)
.background_(Color.grey)
.thumbSize_(40)
.value_(0);

~sliderMasterVol = Slider(~mainWindow, Rect(1100+120, 112, 25, 800))
.action_({
	|slider|
	~reaper.sendMsg("/track/1/volume", slider.value);
})
.knobColor_(Color.black)
.background_(Color.red)
.thumbSize_(40)
.value_(0);

~coordText = StaticText(~mainWindow, Rect(240-25, 112-64, 240, 32))
.string_()
.font_(Font.new(
	"Helvetica",
	24.0
));

~yearText= StaticText(~mainWindow, Rect(480-25, 112-64, 340, 32))
.string_()
.font_(Font.new(
	"Helvetica",
	24.0
));

// There is a GUI with three sliders:
// X, Y and TIME

~mainWindow.front;

// ––// MIDIDefs (BCF) \\––

MIDIdef.new(\bcf_0, {
	|val, chan, source|
	var send_val = val.linlin(0, 127, 0, 1);
	fork {
	{
	~sliderAccelY.valueAction_(send_val);
	}.defer;
	};
}, msgNum: 0, chan: 0, msgType: \control);

MIDIdef.new(\bcf_1, {
	|val, chan, source|
	var send_val = val.linlin(0, 127, 0, 1);
	fork {
	{
	~sliderAccelX.valueAction_(send_val);
	}.defer;
	};
}, msgNum: 1, chan: 0, msgType: \control);

MIDIdef.new(\bcf_2, {
	|val, chan, source|
	var send_val = val.linlin(0, 127, 0, 1);
	fork {
	{
	~sliderTime.valueAction_(send_val);
	}.defer;
	};
}, msgNum: 2, chan: 0, msgType: \control);

MIDIdef.new(\bcf_3, {
	|val, chan, source|
	var send_val = val.linlin(0, 127, 0, 1);
	fork {
	{
	~sliderZoom.valueAction_(send_val);
	}.defer;
	};
}, msgNum: 3, chan: 0, msgType: \control);

MIDIdef.new(\bcf_6, {
	|val, chan, source|
	var send_val = val.linlin(0, 127, 0, 1);
	fork {
	{
	~sliderSubsVol.valueAction_(send_val);
	}.defer;
	};
}, msgNum: 6, chan: 0, msgType: \control);

MIDIdef.new(\bcf_7, {
	|val, chan, source|
	var send_val = val.linlin(0, 127, 0, 1);
	fork {
	{
	~sliderMasterVol.valueAction_(send_val);
	}.defer;
	};
}, msgNum: 7, chan: 0, msgType: \control);
// –– ** OSC Devices ** –– //

~websocketOSC = NetAddr.new("192.168.0.2", 7400);
//  ~websocketOSC = NetAddr.new("10.10.43.27", 7400);
// ~websocketOSC = NetAddr.new("100.67.148.125", 7400);
~reaper = NetAddr("127.0.0.1", 65657);

// Send control data to Reaper:
// Input volume:
~reaper.sendMsg("/track/1/volume", 0);
// Subwoofer send:
~reaper.sendMsg("/track/4/volume", 0);

~cursor = Point(0, 0);
~accel = Point(0, 0);
~timeScale = 0;
~years = 0;
~zoomFactor = 4;

~livingObjects = Dictionary.new();
~playingSynths = Dictionary.new(); // A dictionary with integer keys
~sliderZoom.valueAction_(0);

~websocketOSC.sendMsg("/cursor/reset", ~cursor.x, ~cursor.y);

fork {
	loop {
		~livingObjects = ~getInrange.(~cursor, ~wp);
		~spawnSynths.();
		~killSynths.();

		~livingObjects.keysValuesDo({
			|key, array|
			var dist = array[2];
			var polar = array[3];

			~playingSynths.at(key).set(\polar, polar, \dist, dist, \timeScale, ~timeScale, \zoomFactor, ~zoomFactor);
		});

		~cursor = ~cursor + (~accel * ~timeScale);
		// Keep "in bounds"
		~cursor = ~cursor.min(2048).max(2048.neg);
		~years = ((~years + ~timeScale));
		//	~websocketOSC.sendMsg("/cursor/accel", ~accel.x * ~timeScale, ~accel.y * ~timeScale);
		//		~websocketOSC.sendMsg("/cursor/pos", ~cursor.x, ~cursor.y);
		//		~websocketOSC.sendMsg("/time/scale", ~timeScale);

		(1/60).wait; // Acceleration is related to tic rate, which is not good
		fork {
			{~coordText.string_("%, %".format(~cursor.x.round(0.1), ~cursor.y.round(0.5)));
			~yearText.string_("% years have passed".format(~years.round(1).asInteger))}.defer;
		}
	}
};

// OSCDef to spawn oneshots:

OSCdef(\oneshotReply, {
	|msg|
	var dist = msg[3]; var polar = msg[4];
	~spawnOneshot.(dist, polar);
}, '/oneshotReply');
)
