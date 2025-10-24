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

/*
variables : F G
constants : + −
start  : F
rules  : (F → F+G), (G → F-G)
angle  : 90°

Here, F and G both mean "draw forward", + means "turn left by angle", and − means "turn right by angle".
*/
(
TempoClock.default = TempoClock(150/60);

fork {
    var breaks = [
        Slice(16, ~breaks[16]),
        Slice(16, ~breaks[0], 0.5),
        Slice(16, ~breaks[9], 1),
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
                    pos = (pos + move[dir]) % [breaks.size, 16];
                    breaks[pos[0]].play(pos[1]);
                };
            }
        }
    };

    steps.postln;
};
)


(
~breaks[8].play;
)
