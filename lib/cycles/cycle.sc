CycleSynthNode {
    var server;
    var node;
    var name;
    var args;

    *new { |name, args|
        ^super.newCopyArgs(Server.default, nil, name, args);
    }

    ingestEvent { |event|
        var oldArgs = args;
        args.putAll(event.synthDefArgs);

        if (notNil(event.synthDef)) {
            name = event.synthDef;
        };

        if (notNil(event.spawn) && notNil(name)) {
            server.bind {
                node = Synth.new(name, args.asPairs, server);
                NodeWatcher.register(node);
            }
            ^this;
        };

        if (this.isRunning() && (oldArgs != args)) {
            server.bind {
                var msg = ["/n_set", node.nodeID] ++ args.asPairs;
                server.listSendMsg(msg);
            };
        };
    }

    isRunning {
        ^notNil(node){_.isRunning}
    }
}

CycleSynth {
    var nodes;
    var staticName;
    var staticArgs;

    *new {
        ^super.newCopyArgs([], nil, Dictionary[]);
    }

    ingestEvent { |event|
        var events = event.expand;
        var tmp;
        var nodesPerEvent;

        if (notNil(event.synthDef)) {
            staticName = event.synthDef;
        };

        event.synthDefArgs.pairsDo { |param, binding|
            if (binding.isKindOf(Atom)) {
                // atom bindings are no longer static
                staticArgs.removeAt(param);
            } {
                staticArgs[param] = binding;
            };
        };
        nodes = nodes.removeAllSuchThat{|node, i| not(node.isRunning)};

        while {nodes.size < events.size} {
            nodes = nodes.add(CycleSynthNode(staticName, staticArgs));
        };

        // "chunk" the events based on how many events map to each node.
        nodesPerEvent = nodes.size / events.size;
        nodes.do { |node, i|
            var eventIndex = (i / nodesPerEvent).floor;
            node.ingestEvent(events[eventIndex]);
        };
    }
}

TimelineEvent {
    var <>speed;
    var <>spawn;
    var <>synthDef;
    var <>synthDefArgs;

    *new { |speed, spawn, synthDef, synthArgs=(Dictionary[])|
        synthArgs = Dictionary().putAll(synthArgs);
        ^super.newCopyArgs(speed, spawn, synthDef, synthArgs);
    }

    expand {
        var atomArgs = [];
        var nonAtomArgs = Dictionary[];

        synthDefArgs.keysValuesDo { |param, binding|
            if (binding.isKindOf(Atom)) {
                var unwrapped = binding.unwrap;
                var sublist = [];
                if (unwrapped.isKindOf(SequenceableCollection)) {
                    unwrapped.flatten.do { |val|
                        sublist = sublist.add(param -> val);
                    };
                    atomArgs.add(sublist);
                } {
                    nonAtomArgs[param] = unwrapped;
                };
            } {
                nonAtomArgs[param] = binding;
            };
        };

        if (atomArgs.isEmpty) {
            ^[this];
        };

        ^atomArgs.allTuples.collect { |tuple|
            var newEvent = TimelineEvent(speed, spawn, synthDef, nonAtomArgs);
            tuple.do { |assoc|
                newEvent.synthDefArgs.put[assoc.key] = assoc.value;
            };
            newEvent;
        };
    }

    put { |paramName, paramBinding|
        var empty = { |b| (b == \) || isNil(b) };

        if (empty.(paramBinding)) {
            ^this;
        };

        if (paramName == \speed) {
            this.speed = paramBinding;
            ^this;
        };

        if ((paramName == \spawn) && (paramBinding != 0)) {
            this.spawn = paramBinding;
            ^this;
        };

        if (paramName == \def) {
            this.synthDef = paramBinding;
            ^this;
        };

        synthDefArgs[paramName] = paramBinding;
        ^this;
    }

    postln {
        ("TimelineEvent\n" ++
            "\tspeed=" ++ this.speed ++ "\n" ++
            "\tspawn=" ++ this.spawn ++ "\n" ++
            "\tsynthDef=" ++ this.synthDef ++ "\n" ++
            "\tsynthDefArgs=" ++ this.synthDefArgs).postln;
    }
}

Cycle {
    var cycleSynth;
    var params;
    var clock;

    *new {
        ^super.newCopyArgs(
            CycleSynth(),
            Dictionary[],
            TempoClock(TempoClock.default.tempo));
    }

    add { |paramBinding|
        params[paramBinding.key] = TimeSeq(paramBinding.value);
    }

    run {
        var length = 4;
        var position = 0;

        clock.sched(0, {
            var findMinTime = {
                var minTime = inf;
                params.pairsDo { |param, timeSeq|
                    var event = timeSeq.peek;
                    if (notNil(event)) {
                        minTime = min(minTime, event.time);
                    };
                };
                minTime;
            };

            var collectEventsAt = { |time|
                var timelineEvent = TimelineEvent();
                params.pairsDo { |param, timeSeq|
                    var event = timeSeq.peek;
                    if (notNil(event)) {
                        if (event.time == time) {
                            var binding = timeSeq.next.binding;
                            if (binding.isKindOf(String)) {
                                // best effort attempt to coerce string to note.
                                binding.asString.postln;
                                binding = Note.toFreq(binding);
                            };
                            timelineEvent[param] = binding;
                        };
                    };
                };
                timelineEvent;
            };

            var waitTime;
            var currentTime;
            var event;
            var nextTime;

            currentTime = findMinTime.();
            event = collectEventsAt.(currentTime);

            if (notNil(event.speed)) {
                params.pairsDo { |param, timeSeq|
                    timeSeq.stepSize = event.speed.reciprocal;
                };
            };

            nextTime = findMinTime.();

            position = currentTime;
            waitTime = (nextTime - position);
            cycleSynth.ingestEvent(event);

            (waitTime * length);
        });
    }

    stop {
        clock.clear;
    }
}

TimeSeq {
    var eventStream;
    var peeked;
    var <>stepSize;

    *new { |items, stepSize=1|
        ^super.newCopyArgs(nil, nil, stepSize).init(items);
    }

    init { |items|
        var dfs = { |curr, ratio, totalSteps|
            var currValue = curr.value;
            if (currValue.isKindOf(List)) {
                currValue.do { |binding, i|
                    dfs.(binding, ratio * currValue.size.reciprocal, totalSteps);
                };
            } {
                (time: totalSteps.get, binding: currValue).yield;
                totalSteps.value = totalSteps.value + (ratio * this.stepSize);
            };
        };
        eventStream = r {
            var totalSteps = `0;
            loop {
                dfs.(items, 1, totalSteps);
            };
        };
    }

    peek {
        if (notNil(peeked)) {
            ^peeked;
        };
        peeked = this.next;
        ^peeked;
    }

    next {
        if (isNil(peeked)) {
            ^eventStream.next;
        } {
            var tmp = peeked;
            peeked = nil;
            ^tmp;
        };
    }
}
