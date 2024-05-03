// Function setup:

(
// James code for parsing malformed OSC arrays below:
~parseArray = { |stream|
	var out = Array.new;
	var item;
	// assumes the first [ has already been swallowed
	while {
		item = stream.next;
		item.notNil and: { item != $] }
	} {
		if(item == $[) {
			out = out.add(~parseArray.(stream));
		} {
			out = out.add(item);
		}
	};
	// here, item is either nil (end) or $] (end of array)
	// -- in neither case does the caller need that value
	out
};

~formMessage = { |msg|
	~parseArray.(CollStream(msg));
};

// Loop through the collection of living objects:
// Check if we're supposed to spawn:

~spawnSynths = {
	~livingObjects.pairsDo({
		|key, item|
		~playingSynths.atFail(key, { // Check if there is something associated with the UUID ... item is a float atm
			"There was no Synth playing with UUID %, so I'll spawn one".format(key).postln;
			~playingSynths.add(key -> Synth(\metaSynth, [
				\freq, 110 * [3/2, 5/4, 5/3, 7/4, 9/4, 11/13, 2/1].choose,
				\interval, 1,
				\freq, key.asInteger * 4,
				\bufferN, ~buffersNoise.choose,
				\bufferC, ~buffersSmall.choose,
				\bufferS, ~buffersSub.choose,
				\scaleFactor, rrand(0.9, 1.1),
				\dist, item[3],
				\polar, item[4],
				\amp, 0.5,
				\out, 0 // Try to decode in Reaper...
			]
			) )});
	});
};

// Then check if we're supposed to kill:

~killSynths = {
	~playingSynths.keysDo({ // Looking at the keys of the playing synths:
		|key, index|
		~livingObjects.atFail(key, {
			 "No, there is a Synth that is not supposed to be alive - UID: %, kill it!".format(key).postln;
			~playingSynths.at(key).set(\gate, 0);
			~playingSynths.removeAt(key);
		});
	});
};

~updateSynths = {
	|array|
	array.do({
		|item|
		var key = item[0];
		var distance = item[3];
		var polar = item[4];
		~playingSynths.at(item[0]).set(\polar, polar, \dist, distance);
		// ("UID:" + key + "has polar value" + polar + "and distance:" + distance).postln;
	});
};

~oneShotWeights = [0.1, 1];

~spawnOneshot = {
	|dist = 10, polar = 0|

	// Basically use weighted chance here...

	if ([true, false].wchoose(~oneShotWeights.normalizeSum), // One in 25 chance...
		{
			var index;
			index = rand(~buffersOneshot.size);

			if (~buffersOneshot[index].notNil, {
				"Spawned a oneshot!".postln;
				Synth(\oneShot, [\buffer, ~buffersOneshot[index], \dist, dist, \polar, polar]);
				~buffersOneshot.removeAt(index);
				~oneShotWeights = [0.1, 1];
			}, { "Out of oneshots: array is empty...".postln; }
			);
		},{
			"Did not spawn a oneshot!".postln;
			~oneShotWeights[0] = ~oneShotWeights[0] + 0.01;
		});
};

~livingObjects = Dictionary.new();
~playingSynths = Dictionary.new(); // A dictionary with integer keys

~getInrange = {
	|cursor, wp|
	var edges = [
		cursor.x - (wp[0]/2), cursor.x + (wp[0]/2),
		cursor.y - (wp[1]/2), cursor.y + (wp[1]/2)
	];
	var inRange = Dictionary.new();

	//	("Cursor is at:" + cursor).postln;
	// ("The viewport edges are:" + edges).postln;
	// "The following objects are in range:".postln;
	~soundObjects["soundObjects"].do({
		|obj|
		var x = obj["coords"]["x"].asInteger; // So stupid... convert them when parsing!
		var y = obj["coords"]["y"].asInteger;
		var dx, dy, xd, xy, theta, rad, dict;

		if (
			((x > edges[0]) && (x < edges[1]) && (y > edges[2]) && (y < edges[3])),
			{
				dx = cursor.x - x;
				dy = cursor.y - y;

				xd = x - cursor.x;
				xy = y - cursor.y;

				rad = (xd.pow(2) + xy.pow(2)).sqrt;
				theta = atan2(dx, dy);

				// Maybe remake this to a nested Dict with the UID as key...
				// The theta value in the dict is from the point to the cursor

				inRange.add(obj["uuid"].asInteger -> [x, y, rad, theta]);
				//	"UID: %".format(obj["uuid"]).postln;
				// "Coors = X: %, Y: %".format(x, y).postln;
			}
		)
	});
	//	inRange.postln;
	inRange;
};

)

