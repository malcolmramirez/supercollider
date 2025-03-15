(


var combinations,
    computeDissonance,
    computeDissonances,
    findChord;

combinations = {
    /*
     * Find all combinations with a desiredSize of values from the current array.
     */
    arg desiredSize, currentArray, currentSelection;

    var combs, nextSelection;

    combs = if (currentSelection.size == desiredSize, {
        [currentSelection];
    },
    {
        var intCombs;
        intCombs = List.new;
        currentArray.collect({
            arg item, i;

            var returnedCombs;
            nextSelection = currentSelection.copy;
            nextSelection.add(item);

            returnedCombs = combinations.value(
                desiredSize,
                currentArray.copyRange(i + 1, currentArray.size - 1),
                nextSelection);

            returnedCombs.do({
                arg c, j;
                intCombs.add(c);
            });
        });
        intCombs;
    });

    combs;
};

computeDissonance = {
    /*
     * Compute a dissonance value for a chord, mapped to a 0-1 domain where
     * 0 is most consonant, 1 is most dissonant.
     */
    arg chord;

    var dissonanceRanking, scaleNote;

    scaleNote = {
        arg note;
        while ( { note > 12 }, { note = note - 12 });
        note;
    };

    dissonanceRanking = Dictionary.new;
    // Octave, super consonant
    dissonanceRanking.put(0, 0);
    // Fourth and fifth, highly consonant
    dissonanceRanking.put(5, 1); dissonanceRanking.put(7, 1);
    // m3 and M3, consonant
    dissonanceRanking.put(3, 2); dissonanceRanking.put(4, 2);
    // M2, M6, m7, dissonant
    dissonanceRanking.put(2, 3); dissonanceRanking.put(9, 3); dissonanceRanking.put(10, 3);
    // m6, M7, highly dissonant
    dissonanceRanking.put(8, 4); dissonanceRanking.put(11, 4);
    // m2, tritone, super dissonant
    dissonanceRanking.put(1, 5); dissonanceRanking.put(6, 5);

    // Collect the mean dissonance between all the notes and scale them to 0-1 domain.
    chord.collect({
        arg note, i;
        var chordWithoutNote;

        chordWithoutNote = chord.copy;
        chordWithoutNote.removeAt(i);
        // Take the mean of each sub-pair. Then take the total mean of these means.
        // It works because [ (sum([i1, ..., ik]) / k + ... + sum([j1, ..., jk]) / k) / (n / k) = (sum([i1, ..., ik]) + sum([j1, ..., jk])) / n = sum([i1, ..., ik, ..., j1, ..., jk]) / n = mean
        note = scaleNote.value(note);
        chordWithoutNote.collect({
            arg n2, i;
            var interval;
            n2 = scaleNote.value(n2);
            interval = max(note, n2) - min(note, n2);
            dissonanceRanking.at(interval);
        }).mean;
    }).mean / 5;
};

computeDissonances = {
    /*
     * Compute a dissonance value for a scale and chord size, mapped to a 0-1 domain where
     * 0 is most consonant, 1 is most dissonant.
     */
    arg scale, chordSize;

    var allChords, dissonanceDict;

    dissonanceDict = Dictionary.new;

    allChords = combinations.value(chordSize, scale.degrees, List.new);
    allChords.do({
        arg chord, i;

        var d, chordsWithDissonance;

        d = computeDissonance.value(chord);
        chordsWithDissonance = dissonanceDict.atFail(d, List.new);
        chordsWithDissonance.add(chord);

        dissonanceDict.put(d, chordsWithDissonance);
    });

    dissonanceDict;
};

findChord = {
    /*
     * Find a chord nearest to dval given a map of dissonances in a 0-1 domain to chords.
     */
    arg dval, dissonanceMap;

    var chosenD, minDistance;

    // Keep bounded to the 0-1 domain.
    dval = min(max(dval, 0), 1);
    minDistance = inf;

    dissonanceMap.keys.do({
        arg d;
        var thisDistance;
        thisDistance = (d - dval).abs;
        if (thisDistance < minDistance, {
            chosenD = d;
            minDistance = thisDistance;
        });
    });

    // We are presuming that the dissonance map contains a list of chords.
    dissonanceMap.at(chosenD).choose;
};


d = computeDissonances.value(Scale.phrygian, 3);
findChord.value(0.5, d);

)
