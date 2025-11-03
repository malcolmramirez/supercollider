/**

variables : X F
constants : + − [ ][0, 1]
start  : -X
rules  : (X → F+[[X]-X]-F[-FX]+X), (F → FF)
angle  : 25°


- go up 25d until you hit one, then go down until -1.

- go up 25d from previous pos until you hit (+/-(1/d)) from previous pos.

Here, F means "draw forward", − means "turn right 25°", and + means "turn left 25°". X does not correspond to any drawing action and is used to control the evolution of the curve.
*/

/*

fn fern(segment, angle, pos):

for sym in segment:

if sym == "+"
angle = angle+25deg

if sym == "-"
angle = angle-25deg

if sym == "F"
draw line at angle for unit distance from pos
pos = new pos

if sym == "["
fern(new segment, unit/2, angle, pos.copy)

if sym == "]"
return

if sym == "X"
nothing?

*/
(
var size = 1024;
var fern = Array.fill(size, 0);

/**
variables : X F
constants : + − [ ]
start  : -X
rules  : (X → F+[[X]-X]-F[-FX]+X), (F → FF)
 */
var generateFern = { |n=10|
    var str = ["-", "X"];
    n.do {
        var next = [];
        str.do { |sym|
            if (sym == "X") {
                "F+[[X]-X]-F[-FX]+X".do { |c| next = next.add(c.asString) };
            };
            if (sym == "F") {
                "FF".do { |c| next = next.add(c.asString) };
            };
            if ((sym == "-") || (sym == "X")) {
                next = next.add(sym);
            };
        };
        str = next;
    };
    str;
};

generateFern.(2)
)

/*
variables : F G
constants : + −
start  : F
rules  : (F → F+G), (G → F-G)
angle  : 90°

Here, F and G both mean "draw forward", + means "turn left by angle", and − means "turn right by angle".

F ->
F+G ->
F+G+F-G ->
F+G+F-G+F+G-F-G ->

1 . . . . . . . . . . . . . . . .
2 . . . . . . . . . . . . . . . .
3 . . . . . . . . . . . . . . . .
4 . . . . . . . . . . . . . . . .
*/

(
// Create visualization window
var width = 1510;
var height = 377.5;
var win = Window("l system", Rect(100, 100, width, height))
	.background_(Color.white)
  .front;

var cellWidth = width / 16;
var cellHeight = height / 4;
var trailLifetime = 2.0;  // seconds
var userView = UserView(win, win.view.bounds)
  .background_(Color.white)
  .animate_(true);

~squares = Dictionary[];
~points = Dictionary[];

userView.drawFunc = {
    var now = SystemClock.seconds;
    var lifetime = 1;
    var x, y;
    var dirVectors, dirVec;
    var validSquares, validPoints;

    // Filter expired lines without reassigning
    validSquares = ~squares.values.select({ |square|
        (now - square[\time]) < lifetime
    });
    validSquares.do { |point|
        var age = (now - point[\time]);
        var alpha = (1 - (age / lifetime)) * 0.5;

        x = (point[\pos][1] + 0.5) * cellWidth;
        y = (point[\pos][0] + 0.5) * cellHeight;
        x = x - (cellWidth/2);
        y = y - (cellHeight/2);

        Pen.fillColor = point[\color].alpha_(alpha);
        Pen.fillRect(Rect(x, y, cellWidth * 0.95, cellHeight * 0.95));
        Pen.stroke;
    };
};
)


(
Ndef(\mic, { SoundIn.ar([0, 1]) }).gui;
)

(
Env.perc(0, 1, curve: -4).plot
)

(
var readSoundFiles = { |folder|
    PathName(folder).entries.collect({ |file|
        if (file.extension == "wav") {
            Buffer.read(s, file.fullPath);  // fullPath handles spaces automatically
        };
    });
};

~breaks = readSoundFiles.("~/dev/samples/samples-extra/break");

SynthDef.new(\kick, {
    var sig, modsig, env, freqEnv;

    env = Env.perc(\atk.kr(0.001), \rel.kr(0.25), curve: -2).ar(Done.freeSelf);
    modsig = Saw.ar(\mod.kr(50)) / 4 + 1;

    sig = SinOsc.ar(\freq.kr(100) * (env * \punch.kr(1.2)) * modsig);

    sig = sig * env * \amp.kr(4.dbamp);
    sig = sig!2;

    Out.ar(\out.kr(0), sig);
}).add;

SynthDef.new(\lpf, {
    var sig;

    sig = In.ar(\in.kr, 2);
    sig = LPF.ar(sig, \lpf.kr(5000));
    sig = sig * \amp.kr(1);

    Out.ar(\out.kr(0), sig);
}).add;
)

(
~lpfBus = Bus.audio(s, 2);
~lpfFx = Synth.tail(s, \lpf, [\in, ~lpfBus]);
)

(
~lpfFx.set(\lpf, 250);
~lpfFx.set(\amp, 5.dbamp);
)

(
TempoClock.default = TempoClock(120/60);

fork {
    var breaks = [16, 9, 4, 17].collect { |num, i|
        Slice(~breaks[num], 1)
    };

    var runDragonCurve = { |n=10|
        var str = ["F"];
        n.do {
            var next = [];
            str.do { |sym|
                if (sym == "F") {
                    next = next.add("F").add("+").add("G");
                };
                if (sym == "G") {
                    next = next.add("F").add("-").add("G");
                };
                if ((sym == "+") || (sym == "-")) {
                    next = next.add(sym);
                };
            };
            str = next;
        };
        str;
    };

    var steps = runDragonCurve.();

    fork {
        // 0=e,1=s,2=w,3=n
        var dir = 0;
        var pos = [0, 0];
        var move = [
            [0, 1],  // east
            [1, 0],  // south
            [0, -1], // west
            [-1, 0]  // north
        ];
        loop {
            steps.do { |step|
                if (step == "+") {
                    dir = (dir + 1) % 4;
                };
                if (step == "-") {
                    dir = (dir - 1 + 4) % 4;
                };
                if ((step == "F") || (step == "G")) {
                    var oldPos = pos.copy;
                    pos = (pos + move[dir]) % [breaks.size, 16];

                    ~squares.put(pos, (
                        pos: pos,
                        time: SystemClock.seconds,
                        color: [Color.red, Color.blue, Color.green].choose
                    ));

                    breaks[pos[0]].play(pos[1], out: ~lpfBus, curve: -8);
                };
            }
        }
    };

    fork {
        inf.do { |i|
            var pos = [4.rand, 16.rand];
            s.bind {
                Synth(\kick);
            };
            ~squares.put(pos, (
                pos: pos,
                time: SystemClock.seconds,
                color: Color.black
            ));
            1.wait;
        }
    }
};
)
