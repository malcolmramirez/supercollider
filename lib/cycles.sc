Cycle {
    var <>synth;
    var <>speed;
    var bindings;
    var clock;
    var s;
    var <>stopped;

    *new { |synth, tempo=(TempoClock.default.tempo), s=(Server.default)|
        ^super.newCopyArgs(synth, 1, Dictionary[], TempoClock(tempo), s, false);
    }

    add { |assoc|
        if (assoc.key == \def) {
            this.synth = Synth(assoc.value);
            ^this;
        };

        if (assoc.key == \synth) {
            this.synth = assoc.value;
            ^this;
        };

        if (assoc.key == \speed) {
            this.speed = assoc.value;
            ^this;
        };

        bindings[assoc.key] = assoc.value;
    }

    at { |...associations|
        associations.do { |a| this.add(a) }
    }

    flattenPattern { |pattern, stepSize, offset|
        var result = [];

        var eval = pattern.value;

        if (eval.isKindOf(SequenceableCollection)) {
            var subStepSize = stepSize / eval.size;
            eval.do { |item, i|
                var subOffset = offset + (i * subStepSize);
                result = result ++ this.flattenPattern(item, subStepSize, subOffset);
            };
        } {
            result = result.add((time: offset, val: eval));
        };

        ^result;
    }

    buildTimeline { |length|
        var timeline = Dictionary[];

        bindings.pairsDo { |param, binding|
            var events = this.flattenPattern(binding, length, 0);
            events.do { |event|
                if (event.val != \) {
                    var time = event.time;
                    var timelineEntry = timeline.atFail(time, []);
                    timelineEntry = timelineEntry.add(param);
                    timelineEntry = timelineEntry.add(event.val);
                    timeline[time] = timelineEntry;
                };
            };
        };

        ^timeline;
    }

    run { |length=4|

        length = length * speed.reciprocal;

        // Start the first cycle
        clock.sched(0, {
            var timeline = this.buildTimeline(length);

            timeline.pairsDo { |time, values|
                clock.sched(time, {
                    s.bind {
                        s.listSendMsg(
                            ["/n_set", this.synth.nodeID] ++ values
                        );
                    };
                });
            };

            length;
        });
    }

    leftShift { |...associationOverrides|
        this.stop;
        associationOverrides.do { |a| this.add(a) };
        this.run;
    }

    stop {
        clock.clear;
    }
}

Alt {
    var items;
    var ptr;

    *new { |...items|
        ^super.newCopyArgs(items, 0);
    }

    value {
        var tmp = items[ptr];
        ptr = (ptr + 1) % items.size;
        ^tmp.value;
    }
}

Euc {
    var k;
    var n;
    var o;
    var on;
    var off;

    *new { |k, n, o=0, on=1, off=\|
        ^super.newCopyArgs(k, n, o, on, off);
    }

    value {
        var items = (
            (k / n * (0..n - 1))
            .floor
            .differentiate
            .asInteger
            .min(1)[0] = if (k <= 0) { 0 } { 1 }
        );
        items = items.rotate(o.value);
        items = items.collect({|i| if (i == 0) { off.value } { on.value }});
        ^items;
    }
}