Note {
    classvar chordTable;

    *initChordTable {
        chordTable = Dictionary[
            "maj" -> [0, 4, 7],
            "aug" -> [0, 4, 8],
            "6" -> [0, 4, 7, 9],
            "69" -> [0, 4, 7, 9, 14],
            "maj7" -> [0, 4, 7, 11],
            "maj9" -> [0, 4, 7, 11, 14],
            "add9" -> [0, 4, 7, 14],
            "maj11" -> [0, 4, 7, 11, 14, 17],
            "add11" -> [0, 4, 7, 17],
            "maj13" -> [0, 4, 7, 11, 14, 21],
            "add13" -> [0, 4, 7, 21],
            "dom7" -> [0, 4, 7, 10],
            "dom9" -> [0, 4, 7, 14],
            "dom11" -> [0, 4, 7, 17],
            "dom13" -> [0, 4, 7, 21],
            "7f5" -> [0, 4, 6, 10],
            "7s5" -> [0, 4, 8, 10],
            "7f9" -> [0, 4, 7, 10, 13],
            "9" -> [0, 4, 7, 10, 14],
            "11" -> [0, 4, 7, 10, 14, 17],
            "13" -> [0, 4, 7, 10, 14, 17, 21],
            "min" -> [0, 3, 7],
            "dim" -> [0, 3, 6],
            "mins5" -> [0, 3, 8],
            "min6" -> [0, 3, 7, 9],
            "min69" -> [0, 3, 9, 7, 14],
            "min7f5" -> [0, 3, 6, 10],
            "min7" -> [0, 3, 7, 10],
            "min7s5" -> [0, 3, 8, 10],
            "min7f9" -> [0, 3, 7, 10, 13],
            "min7s9" -> [0, 3, 7, 10, 15],
            "dim7" -> [0, 3, 6, 9],
            "min9" -> [0, 3, 7, 10, 14],
            "min11" -> [0, 3, 7, 10, 14, 17],
            "min13" -> [0, 3, 7, 10, 14, 17, 21],
            "minmaj7" -> [0, 3, 7, 11],
            "1" -> [0],
            "5" -> [0, 7],
            "sus2" -> [0, 2, 7],
            "sus4" -> [0, 5, 7],
            "7sus2" -> [0, 2, 7, 10],
            "7sus4" -> [0, 5, 7, 10],
            "9sus4" -> [0, 5, 7, 10, 14],
            "7s10" -> [0, 4, 7, 10, 15],
            "9s5" -> [0, 1, 13],
            "min9s5" -> [0, 1, 14],
            "7s5f9" -> [0, 4, 8, 10, 13],
            "min7s5f9" -> [0, 3, 8, 10, 13],
            "11s" -> [0, 4, 7, 10, 14, 18],
            "min11s" -> [0, 3, 7, 10, 14, 18]
        ];
    }

    *new { |...names|
        var seqInt = { |name|
            if (name.isKindOf(String)) {
                Note.toFreq(name);
            } {
                if (name.isKindOf(SequenceableCollection)) {
                    name.do { |n| seqInt.(n) }
                };
            };
        };
        ^names.collect { |name| seqInt.(name) };
    }

    *toFreq { |name|
        // note + chordname
        var splitName = name.split($_);
        var note = splitName.first.toLower;
        var chord = splitName.last.toLower;

        var octave;
        var noteName;
        var noteNumber;

        if (splitName.size > 2) {
            Error(
                "Chord name must be in the form of <note>_<type>, " +
                "where type is a valid chord").throw;
        };

        if ((note.size) < 2 || (note.size) > 3) {
            Error("Note must be in the form of <note><octave>").throw;
        };
        if (chordTable == nil) {
            Note.initChordTable;
        };
        octave = note.last.asString.asInteger;

        noteName = if (note.size == 2) {
            note[0].asString;
        } {
            note[0].asString ++ note[1].asString;
        };

        noteNumber = switch(noteName,
            "cf", {-1}, "c",  {0},  "cs", {1},
            "df", {1},  "d",  {2},  "ds", {3},
            "ef", {3},  "e",  {4},  "es", {5},
            "ff", {4},  "f",  {5},  "fs", {6},
            "gf", {6},  "g",  {7},  "gs", {8},
            "af", {8},  "a",  {9},  "as", {10},
            "bf", {10}, "b",  {11}, "bs", {12}
        );

        noteNumber = (((octave + 1) * 12) + noteNumber);
        ^if (splitName.size == 1) {
            noteNumber.midicps;
        } {
            Atom(chordTable[chord].collect{|num|
                (num + noteNumber).midicps;
            });
        };
    }
}