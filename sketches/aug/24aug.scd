(
// Load drums
~cpu = PathName("~/dev/samples/samples-extra/cpu2").entries.collect({
    arg path;
    Buffer.read(s, path.fullPath);
}).select(_.notNil);

)

(

var initialPattern = (
    kd: [1, 0, 0, 0, 1, 0, 0, 0],
    oh: [0, 0, 0.7, 0, 0, 0, 0.7, 0],
    sd: [0, 0, 0, 0, 1, 0, 0, 0]
);

var patternInitializer = {
    (
        kd: initialPattern.kd.copy,
        oh: initialPattern.oh.copy,
        sd: initialPattern.sd.copy
    )
};

var patternMutation = {
    arg pattern;
    var newPattern = (
        kd: pattern.kd.copy,
        oh: pattern.oh.copy,
        sd: pattern.sd.copy
    );

    // Choose which instrument to mutate
    var instruments = [\kd, \oh, \sd];
    var targetInstrument = instruments.choose;
    var targetArray = newPattern[targetInstrument];

    // Choose mutation type
    switch(3.rand,
        0, {
            // Flip a step (0->random value, >0->0)
            var pos = targetArray.size.rand;
            if (targetArray[pos] > 0, {
                targetArray[pos] = 0;
            }, {
                targetArray[pos] = [0.3, 0.5, 0.7, 0.9, 1.0].choose;
            });
        },
        1, {
            // Adjust velocity/probability
            var pos = targetArray.size.rand;
            if (targetArray[pos] > 0, {
                targetArray[pos] = (targetArray[pos] + [-0.2, -0.1, 0.1, 0.2].choose).clip(0.1, 1.0);
            });
        },
        2, {
            // Shift pattern left or right
            var shift = [-2, 2].choose;
            targetArray = targetArray.rotate(shift);
            newPattern[targetInstrument] = targetArray;
        }
    );

    newPattern
};

// Crossover function - combines two patterns
var patternCrossover = {
    arg parent1, parent2;
    var child = (
        kd: Array.newClear(8),
        oh: Array.newClear(8),
        sd: Array.newClear(8)
    );

    // For each instrument, blend the parents
    [\kd, \oh, \sd].do({ arg instrument;
        8.do({ arg i;
            // Random blend between parents
            if (0.5.coin, {
                child[instrument][i] = parent1[instrument][i];
            }, {
                child[instrument][i] = parent2[instrument][i];
            });

            // Occasionally average the values
            if (0.2.coin && (parent1[instrument][i] > 0) && (parent2[instrument][i] > 0), {
                child[instrument][i] = (parent1[instrument][i] + parent2[instrument][i]) / 2;
            });
        });
    });

    child
};

// Filter function - evaluates pattern fitness
var patternFilter = {
    arg pattern;
    var score = 0;
    var totalHits, hihatHits, kdVariation;

    // Check if pattern has the expected structure
    if (pattern.kd.isNil || pattern.oh.isNil || pattern.sd.isNil, { ^false });

    // Prefer patterns with some activity
    totalHits = pattern.kd.sum + pattern.oh.sum + pattern.sd.sum;
    if (totalHits < 1, { ^false }); // Reject completely empty patterns
    if (totalHits > 10, { ^false }); // Reject overly busy patterns

    // Reward kick drum on strong beats (positions 0, 4)
    if ((pattern.kd.size > 0) && (pattern.kd[0] > 0), { score = score + 2 });
    if ((pattern.kd.size > 4) && (pattern.kd[4] > 0), { score = score + 1 });

    // Reward snare on backbeat (position 4)
    if ((pattern.sd.size > 4) && (pattern.sd[4] > 0), { score = score + 2 });

    // Count hi-hat hits
    hihatHits = 0;
    pattern.oh.do({ arg val; if (val > 0, { hihatHits = hihatHits + 1 }); });
    if ((hihatHits >= 2) && (hihatHits <= 4), { score = score + 1 });

    // Count kick drum variation
    kdVariation = 0;
    pattern.kd.do({ arg val; if (val > 0, { kdVariation = kdVariation + 1 }); });
    if ((kdVariation >= 2) && (kdVariation <= 4), { score = score + 1 });

    // Random factor for diversity
    if (0.3.coin, { score = score + 1 });

    // Accept patterns with score >= 3
    score >= 3
};

// Create the genetic simulation
~drumSim = GeneticSimulation.new(
    patternMutation,
    patternFilter,
    patternCrossover,
    patternInitializer,
    100, // population size
    0.15 // mutation probability
);

)

(

var dpMap = (
    kd: 0,
    oh: 6,
    sd: [3, 18]
);

var initSequence = {
    arg key, pattern, beatdur;
    pattern = pattern[key];
    Routine({
        var sample = dpMap[key];
        pattern.do({
            arg elem;
            if (elem > 0, {
                if (sample.isKindOf(Collection), {
                    sample.do({
                        arg item, i;
                        var mul = elem / sample.size;
                        ~cpu[item].play(mul: mul);
                    });
                },
                {
                    ~cpu[sample].play(mul: elem);
                });
            });
            0.25.wait;
        });
    });
};

var clock = TempoClock.new(145/60);

Routine({
    loop {
        var numBeats = 2;
        dpMap.keysDo({
            arg key;
            var next = ~drumSim.next;
            next.postln;
            initSequence.value(
                key,
                next,
                numBeats / next[key].size).play(clock: clock);
        });
        numBeats.wait;
    }
}).play(clock: clock);

)