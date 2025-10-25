(
var readSoundFiles = { |folder|
    PathName(folder).entries.collect({ |file|
        if (file.extension == "wav") {
            Buffer.read(s, file.fullPath);  // fullPath handles spaces automatically
        };
    });
};

~breaks = readSoundFiles.("~/dev/samples/samples-extra/break");
)

(
SynthDef(\fm, {
    var sig, env;

    sig = SinOsc.ar(
        \freq.kr(220) * SinOsc.ar(\modfreq.kr(220) *
            SinOsc.ar(\modfreq.kr(220) *
                Line.ar(Rand(0.1, 0.5), 1, \rel.kr(1)))));
    env = Env.perc(\atk.kr(0.1), \rel.kr(1)).ar(Done.freeSelf);

    sig = sig * env;

    sig = LPF.ar(RLPF.ar(sig, \rlpf.kr(110), Line.ar(1, 0.1, 0.5)), \lpf.kr(110));

    Out.ar(\out.kr(0), sig ! 2);
}).add;
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
TempoClock.default = TempoClock(150/60);

fork {
    var breaks = [
        Slice(16, ~breaks[16]),
        Slice(16, ~breaks[9], 1),
        Slice(16, ~breaks[4], 1),
        Slice(16, ~breaks[17]),
    ];

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

                    breaks[pos[0]].play(pos[1]);
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
    };

    fork {
        inf.do { |i|
            (440 * [1, 3/2, ]).do { |freq|
                s.bind {
                    Synth(\fm, [\freq, freq]);
                };
            };
            4.wait;
        }
    };
};
)
