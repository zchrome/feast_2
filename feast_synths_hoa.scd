(
var smallPath, noisePath, oneshotPath, subPath;

Buffer.freeAll;

~curFile = PathName(thisProcess.nowExecutingPath);
~cwd = PathName(~curFile.pathOnly); // Buffer loading interfers with JSON parsing...
~imagesPath = ~cwd +/+ "/images"; // Ugly!
~soundFilesPath = ~cwd +/+ "/sound files"; // Ugly!

noisePath = ~soundFilesPath +/+ "/noise";
smallPath = ~soundFilesPath +/+ "/small";
oneshotPath = ~soundFilesPath +/+ "/oneshot";
subPath = ~soundFilesPath +/+ "/basses";

~buffersNoise = noisePath.entries.collect({
	|item|
	Buffer.readChannel(s, item.fullPath, channels: [0]);
});

~buffersSmall = smallPath.entries.collect({
	|item|
	Buffer.readChannel(s, item.fullPath, channels: [0]);
});

~buffersOneshot = oneshotPath.entries.collect({
	|item|
	Buffer.readChannel(s, item.fullPath, channels: [0]);
});

~buffersSub = subPath.entries.collect({
	|item|
	Buffer.readChannel(s, item.fullPath, channels: [0]);
});
)

(
SynthDef(\metaSynth, {
	|freq = 440, interval = 1, amp = 1,
	dist = 0.5, polar = 0,
	bufferN = 0, bufferC = 0, bufferS = 0,
	out = 0, subOut = 15, gate = 1, xfade = -1,
	scaleFactor = 1, zoomFactor = 1|
	var noiseSig, closeSig,	subSig, sig, dist_amp, dist_plane, dist_rad, dist_fade, pan_pos, env;

	dist = dist.lag(1).max(1) * zoomFactor.linlin(1, 4, 1.5, 1); // Should solve?
	pan_pos = polar.lag(0.5);

	// Calculate distances... tweak?

	dist_rad = dist.linlin(0, 400, 0.5, 10); // Tweak? 50 cm to 10 meters...
	dist_amp = dist.linexp(0, 400, 0.dbamp, -30.dbamp);
	dist_plane = dist.linlin(0, 400, 0, pi/2);
	dist_fade = dist.linlin(0, 400, 6.dbamp, -60.dbamp);

	noiseSig = PlayBuf.ar(numChannels: 1, bufnum: bufferN, rate: 1, trigger: 1, loop: 1);

	// Simulate some browninain motion:

	//	noiseSig = noiseSig * (LFBrownNoise0.kr(0.5).range(0.5, 1) * dist_rad.linlin(0.5, 10, 0.1, 1));

	closeSig = BufRd.ar(
		numChannels: 1,
		bufnum: bufferC,
		phase: Phasor.ar(
			trig: 0,
			rate: BufRateScale.kr(bufferC) * scaleFactor,
			start: 0,
			end: BufFrames.kr(bufferC)
		)
	);

	//	subSig = PlayBuf.ar(1, bufferS, rate: 1, trigger: 1, loop: 1) * 0.05 * dist_amp;
	//	Out.ar(subOut, subSig);

	closeSig = closeSig * 0.35;

	SendReply.kr(
		trig: InRange.kr(dist, lo: 0, hi: 50),
		cmdName: '/oneshotReply', values: [dist, polar]);

	closeSig = closeSig * LFNoise2.kr(0.5 * scaleFactor).range(0, 1);
	closeSig = closeSig * dist_fade * zoomFactor.linexp(1, 4, 0.dbamp, 6.dbamp);
	noiseSig = noiseSig * zoomFactor.explin(1, 4, 0.dbamp, -24.dbamp);

	//noiseSig = HPF.ar(LPF.ar(noiseSig, zoomFactor.linexp(1, 4, 20000, 400)), zoomFactor.linexp(1, 4, 10, 300));

	// Filter out lo frequencies and send to a sub bus...
	// Or just decode to stereo and send...

	sig = Mix.ar([closeSig, noiseSig]);

	env = Env.adsr(attackTime: 6, releaseTime: 4).kr(gate: gate, doneAction: 2);

	sig = sig * env;
	sig = sig * dist_amp;
	sig = sig * amp;

	// Encode to second order HOA:
	// This UGen takes an argument that describes the physical dimensions of the speaker setup. Look up!
	// Distance = 0 is an invalid value!
	// Should induce a "proximity effect" (bass boost)

	sig = HoaEncodeDirection.ar(sig, theta: pan_pos, radius: dist_rad, order: 2);
	Out.ar(out, sig); // B-format signal to decoder
}).add;

SynthDef(\oneShot, {
	|amp = 0.1, dist = 0.5, buffer = 0, out = 0, polar = 0|
	var sig, dist_amp, dist_rad, pan_pos, env;

	dist = dist.lag(1);

	dist_rad = dist.linlin(0, 400, 0.1, 10);
	pan_pos = polar;

	sig = PlayBuf.ar(
		numChannels: 1,
		bufnum: buffer,
		rate: 1,
		trigger: 1,
		loop: 0,
		doneAction: 2
	);

	sig = sig * 0.75;

	env = Env.perc(releaseTime: BufDur.kr(buffer)).kr();
	sig = sig * env * amp;
	sig = HoaEncodeDirection.ar(sig, theta: pan_pos, radius: dist_rad, order: 2); // What the fuck I am in second order!!!!
Out.ar(out, sig);
}).add;

)

// InRange -> TWCHoose -> IF 1 -> BufRd + SendReply (trigger once)
// Just send a Reply and that spawns a synth with the data...
// InRange will fire multiple times per control rate!
