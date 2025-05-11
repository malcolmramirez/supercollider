Server.default.options.outDevice_("blackhole+phones");

s.boot;
s.quit;

Platform.userExtensionDir;

(

SynthDef.new(\tone, {
    arg amp, atk, dec,
        freq, out;

    var env, sig;

    env = EnvGen.kr(Env.perc(atk, dec), doneAction:2);

    // https://github.com/supercollider/sc3-plugins
    sig = DiodeRingMod.ar(SinOsc.ar(freq), LFTri.ar(freq));
    sig = Splay.ar(sig);
    sig = sig * env * amp;

    Out.ar(out, sig.softclip);
}).add;

SynthDef.new(\reverb, {
    arg in, out,
        mix = 1, room = 0.99, damp = 0.25,
        amp = 1.0;

    var sig, reverbed;

    sig = In.ar(in, 2);
    sig = FreeVerb2.ar(
        sig[0],
        sig[1],
        mix,
        room,
        damp
    );

    sig = sig * amp;
    sig = sig.softclip;

    Out.ar(out, sig);
}).add;

)

(
var circleSize = 7.5;
var pos = [0, 0];
var sel = nil;
var circleProject = {
    arg x, y, r;
    var dx, dy, dr, d,
        px, py,
        polar, pt,
        pd1, pd2;

    pt = [x, y];

    dx = x - r;
    dy = y - r;
    dr = (dx.pow(2) + dy.pow(2)).sqrt;

    // assumes that the center is r,r
    if (dr > r, {
        polar = Polar.new(r, (dy/dx).atan);
        pt = [polar.real, polar.imag];

        if (dx < 0, {
            pt = r - pt;
        }, {
            pt = r + pt;
        });
    });

    pt;
};

~faceRadius = 200;

~window = Window.new.front;
~window.background = Color.white;

// (1) create a UserView

~view = UserView(~window, Rect(0, 0, ~faceRadius*2, ~faceRadius*2));

~faceDict = Dictionary();
~faceDict.put(\lefteye, [100, 150]);
~faceDict.put(\righteye, [300, 150]);

~faceDict.put(\nosetop, [200, 150]);
~faceDict.put(\nosetip, [250, 225]);
~faceDict.put(\nosebottom, [200, 250]);

~faceDict.put(\mouthleft, [100, 275]);
~faceDict.put(\mouthright, [300, 275]);
~faceDict.put(\mouthmiddle, [200, 350]);

// (2) define a drawing function using Pen
~view.drawFunc = {
    var leftEyePos, rightEyePos,
        noseTop, noseTip, noseBottom,
        mouthLeft, mouthRight, mouthMiddle,
        mouthControl;

    // face frame
    Pen.width = 2;
    Pen.fillColor = Color.rand;
    Pen.strokeOval(Rect(0, 0, ~faceRadius*2, ~faceRadius*2));

    // --- eyes ---
    // left eye
    leftEyePos = ~faceDict.at(\lefteye);
    Pen.fillOval(Rect(leftEyePos[0], leftEyePos[1], circleSize, circleSize));

    // right eye
    rightEyePos = ~faceDict.at(\righteye);
    Pen.fillOval(Rect(rightEyePos[0], rightEyePos[1], circleSize, circleSize));

    // --- nose ---
    noseTop = ~faceDict.at(\nosetop);
    Pen.moveTo(noseTop[0]@noseTop[1]);

    noseTip = ~faceDict.at(\nosetip);
    noseBottom = ~faceDict.at(\nosebottom);
    Pen.lineTo(noseTip[0]@noseTip[1]);
    Pen.quadCurveTo(noseBottom[0]@noseBottom[1], (noseTip[0]-20)@(noseTip[1]+30));
    Pen.stroke;

    // control point indicators
    Pen.fillOval(Rect(noseTop[0]-2, noseTop[1]-2, circleSize, circleSize));
    Pen.fillOval(Rect(noseTip[0]-4, noseTip[1]-3, circleSize, circleSize));
    Pen.fillOval(Rect(noseBottom[0]-2, noseBottom[1]-3.5, circleSize, circleSize));

    // --- mouth ---
    mouthLeft = ~faceDict.at(\mouthleft);
    mouthRight = ~faceDict.at(\mouthright);
    mouthMiddle = ~faceDict.at(\mouthmiddle);

    // when middle is below right and left, smile,
    // when middle is above right and left, frown
    // when middle is in line with right and left, neutral

    Pen.moveTo(mouthMiddle[0]@mouthMiddle[1]);
    mouthControl = mouthLeft + [
        ((mouthMiddle[0] - mouthLeft[0]) - (mouthMiddle[1] - mouthLeft[1])) * (-1/16),
        (mouthMiddle[1] - mouthLeft[1])
    ];

    Pen.quadCurveTo(mouthLeft[0]@mouthLeft[1], mouthControl[0]@mouthControl[1]);

    Pen.moveTo(mouthMiddle[0]@mouthMiddle[1]);
    mouthControl = mouthRight + [
        ((mouthMiddle[0] - mouthRight[0]) + (mouthMiddle[1] - mouthRight[1])) * (-1/16),
        (mouthMiddle[1] - mouthRight[1])
    ];
    Pen.quadCurveTo(mouthRight[0]@mouthRight[1], mouthControl[0]@mouthControl[1]);
    Pen.stroke;

    // control point indicators
    Pen.fillOval(Rect(mouthLeft[0]-2, mouthLeft[1]-2, circleSize, circleSize));
    Pen.fillOval(Rect(mouthMiddle[0]-3, mouthMiddle[1]-4, circleSize, circleSize));
    Pen.fillOval(Rect(mouthRight[0]-3, mouthRight[1]-3, circleSize, circleSize));
};

// (3) set the default action
~view.action = { ~view.refresh };

// (4) define mouse actions
~view.mouseDownAction = { arg view, x, y, m;
    pos = circleProject.value(x, y, ~faceRadius);
    if (sel != nil, {
        ~faceDict.put(sel, pos);
    }, {
        ~faceDict.keysValuesDo({
            arg key, val;
            var dist, dx, dy;
            dist = (pos - val).abs;
            if ((dist[0] < 11) && (dist[1] < 11), {
                sel = key;
            });
        });

        if (sel != nil, {
            ~faceDict.put(sel, pos);
        });
    });

    ~view.doAction;
};

~view.mouseMoveAction = ~view.mouseDownAction;

~view.mouseUpAction = {
    sel = nil;
};

// (6) (optional) define drag and drop behavior
~view.beginDragAction = {
    arg view, x, y;
    sel;
}; // what to drag

~view.canReceiveDragHandler = { View.currentDrag != nil }; // what to receive

~view.receiveDragHandler = {
    arg view, x, y;
    pos = [x, y];
    ~view.doAction;
}; // what to do on receiving

)

(

~dist = {
    arg p1, p2;
    ((p1[1] - p2[1]).pow(2) + (p1[0] - p2[0]).pow(2)).sqrt;
};

~noteFunction = {
    var notes, avgSmileFactor;

    notes = [
        [0, 4, 7, 12], // majorer
        [0, 4, 7, 16], // ???
        [0, 4, 7], // maj
        [0, 4, 7, 13], // ???
        [0, 3, 7, 10], // min7
        [0, 4, 7, 11], // ???
        [0, 3, 7, 11], // majmin7
        [0, 3, 7], // min
        [0, 4, 8], // aug
        [0, 3, 6], // dim
    ];

    avgSmileFactor = ~faceDict[\mouthright][1] - ~faceDict[\mouthmiddle][1];
    avgSmileFactor = avgSmileFactor + (~faceDict[\mouthleft][1] - ~faceDict[\mouthmiddle][1]);
    avgSmileFactor = (avgSmileFactor / 2).linlin(-2*~faceRadius, 2*~faceRadius, 0, notes.size);
    //notes[avgSmileFactor].postln;

    notes[avgSmileFactor];
};

~octaveSpread = {
    var mouthDist;
    mouthDist = ~dist.value(~faceDict[\mouthright], ~faceDict[\mouthleft]);
    mouthDist = mouthDist.linlin(0, 2*~faceRadius, 0, 4);
    (0..mouthDist) + 2;
};

~durFunction = {
    var noseDist, durs,
        noseDistBottomTip,
        randP,
        randd, randLo, randHi,
        dur;

    durs = [1,2,3,4,8,12,16] / 8;

    noseDist = ~dist.value(~faceDict[\nosetop], ~faceDict[\nosebottom]);

    noseDistBottomTip =  ~dist.value(~faceDict[\nosetip], ~faceDict[\nosebottom]);
    randP = noseDistBottomTip.linlin(0, 2*~faceRadius, 0, 100);

    randHi = noseDistBottomTip.linlin(0, 2*~faceRadius, 0, durs.size);
    noseDist = noseDist.linlin(0, 2*~faceRadius, 0, durs.size);

    if (100.rand < randP, {
        randd = randHi.rand;
        dur = durs.wrapAt(noseDist + randHi.rand);
    }, {
        dur = durs[noseDist];
    });
    dur;
};

~arpDurFunction = {
    var eyeDist, durs,
        eyeSkew,
        randP,
        randRange, randLo, randHi,
        dur;

    durs = (4..16).reciprocal;
    durs = durs.reverse;

    eyeDist = ~dist.value(~faceDict[\lefteye], ~faceDict[\righteye]);

    eyeSkew = (~faceDict[\lefteye][1] - ~faceDict[\righteye][1]).abs;
    randP = eyeSkew.linlin(0, 2*~faceRadius, 0, 100);
    //eyeSkew.postln;
    //randP.postln;

    randHi = eyeSkew.linlin(0, 2*~faceRadius, 0, durs.size);
    eyeDist = eyeDist.linlin(0, 2*~faceRadius, 0, durs.size);

    if (100.rand < randP, {
        dur = durs.wrapAt(eyeDist + randHi.rand);
    }, {
        dur = durs[eyeDist];
    });
    dur;
};

~arpOctaveSpread = {
    var eyeXDist;
    eyeXDist = (~faceDict[\lefteye][0] - ~faceDict[\righteye][0]).abs;
    eyeXDist = eyeXDist.linlin(0, 2*~faceRadius, 0, 6);
    (0..eyeXDist) + 2;
};

~scaleTo = {
    arg num, max;
    num.linlin(0, 2*~faceRadius, 0, max);
};

~rbus = Bus.audio(s, 2);
~rbus2 = Bus.audio(s, 2);

~tonePattern = Pbind(
    \instrument, \tone,
    \dur, Pfuncn({~durFunction.value}, inf),
    \scale, Scale.new((0..12)),
    \octave, Pn(Plazy({Pseq(~octaveSpread.value)})),
    \degree, Pfuncn({~noteFunction.value}, inf),
    \atk, Pkey(\dur) * 1/4,
    \dec, Pkey(\dur) * 3/4,
    \out, ~rbus,
    \amp, 0.1);

~tonePattern = Pfx(
    ~tonePattern,
    \reverb,
    \in, ~rbus,
    \out, 0,
    \mix, 1,
    \amp, 0.5,
    \damp, 0.1);

~arpPattern = Pbind(
    \instrument, \tone,
    \dur, Pfuncn(~arpDurFunction, inf),
    \scale, Scale.new((0..12)),
    \octave, Pn(Plazy({Pseq(~arpOctaveSpread.value)})),
    \degree, Pfuncn({~noteFunction.value.choose}, inf),
    \atk, Pkey(\dur) * 1/4,
    \dec, Pkey(\dur) * 3/4,
    \out, ~rbus2,
    \amp, 0.2);

~arpPattern = Pfx(
    ~arpPattern,
    \reverb,
    \in, ~rbus2,
    \out, 0,
    \mix, 0.25,
    \amp, 0.25,
    \damp, 0.5);

Ppar([~tonePattern, ~arpPattern]).play;
)