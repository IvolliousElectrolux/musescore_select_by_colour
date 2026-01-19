//=============================================================================
//  Select Elements by Colour
//
//  Select all elements of a specified colour in the score or within selection.
//  Compatible with MuseScore 4.4+
//
//  Copyright (C) 2026
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 3 as
//  published by the Free Software Foundation.
//=============================================================================

import QtQuick
import QtQuick.Controls

import MuseScore 3.0
import Muse.Ui
import Muse.UiComponents

MuseScore {
    version: "1.2"
    title: qsTr("Select by Colour")
    description: qsTr("Select elements of a specified colour in the score or selection")
    categoryCode: "composing-arranging-tools"
    pluginType: "dialog"
    requiresScore: true

    width: 460
    height: 480

    // Default target colour (black, fully opaque)
    property string targetColourHex: "#000000"
    property int targetAlpha: 255
    property int matchedCount: 0
    property bool elementPanelVisible: false

    // Element type filters
    property bool matchNote: true
    property bool matchStem: false
    property bool matchBeam: false
    property bool matchHook: false
    property bool matchNoteDot: false
    property bool matchSlur: false
    property bool matchTie: false
    property bool matchAccidental: false
    property bool matchArticulation: false
    property bool matchRest: false
    property bool matchLyrics: false
    property bool matchDynamic: false
    property bool matchHairpin: false
    property bool matchOttava: false
    property bool matchPedal: false

    onRun: {}

    // Get full ARGB string (#aarrggbb format)
    function getFullColorString() {
        var alpha = targetAlpha.toString(16)
        if (alpha.length < 2) alpha = "0" + alpha
        return "#" + alpha + targetColourHex.substring(1)
    }

    // Parse color string, returns {rgb: "#rrggbb", alpha: 0-255}
    function parseColorString(colorStr) {
        var s = colorStr.toString().toLowerCase()
        if (s.length === 9 && s.charAt(0) === '#') {
            var alpha = parseInt(s.substring(1, 3), 16)
            var rgb = "#" + s.substring(3)
            return {rgb: rgb, alpha: alpha}
        } else if (s.length === 7 && s.charAt(0) === '#') {
            return {rgb: s, alpha: 255}
        }
        return {rgb: "#000000", alpha: 255}
    }

    // Compare colours
    function colorsMatch(elementColor) {
        var colorInfo = parseColorString(elementColor)
        var targetRgb = targetColourHex.toLowerCase()

        if (colorInfo.rgb !== targetRgb) {
            return false
        }

        if (matchAlphaCheck.checked) {
            return colorInfo.alpha === targetAlpha
        }

        return true
    }

    // Check if element type should be matched
    function shouldMatchType(elementType) {
        switch (elementType) {
            case Element.NOTE: return matchNote
            case Element.STEM: return matchStem
            case Element.BEAM: return matchBeam
            case Element.HOOK: return matchHook
            case Element.NOTEDOT: return matchNoteDot
            case Element.SLUR: return matchSlur
            case Element.TIE: return matchTie
            case Element.ACCIDENTAL: return matchAccidental
            case Element.ARTICULATION: return matchArticulation
            case Element.REST: return matchRest
            case Element.LYRICS: return matchLyrics
            case Element.DYNAMIC: return matchDynamic
            case Element.HAIRPIN: return matchHairpin
            case Element.OTTAVA: return matchOttava
            case Element.PEDAL: return matchPedal
            default: return false
        }
    }

    // Check element and add to list if matches
    // For sub-elements that can't be selected directly, select parent note/chord instead
    function checkElement(el, elementsToSelect, selectableElements) {
        if (!el || el.color === undefined) return
        if (shouldMatchType(el.type) && colorsMatch(el.color)) {
            matchedCount++
            // These element types can be selected directly
            if (el.type === Element.NOTE || el.type === Element.REST ||
                el.type === Element.SLUR || el.type === Element.HAIRPIN ||
                el.type === Element.OTTAVA || el.type === Element.PEDAL ||
                el.type === Element.DYNAMIC || el.type === Element.LYRICS) {
                selectableElements.push(el)
            }
            elementsToSelect.push(el)
        }
    }

    // Helper to add note to selectable list (avoid duplicates)
    function addNoteToSelect(note, selectableElements) {
        for (var i = 0; i < selectableElements.length; i++) {
            if (selectableElements[i] === note) return
        }
        selectableElements.push(note)
    }

    // Process chord and its sub-elements
    function processChord(chord, elementsToSelect, selectableElements) {
        var chordHasMatch = false

        // Notes
        if (matchNote) {
            for (var n = 0; n < chord.notes.length; n++) {
                var note = chord.notes[n]
                if (colorsMatch(note.color)) {
                    elementsToSelect.push(note)
                    selectableElements.push(note)
                    matchedCount++
                }
            }
        }

        // Note-attached elements (select the note if these match)
        for (var n2 = 0; n2 < chord.notes.length; n2++) {
            var note2 = chord.notes[n2]

            // Note dots
            if (matchNoteDot && note2.dots) {
                for (var d = 0; d < note2.dots.length; d++) {
                    if (note2.dots[d] && colorsMatch(note2.dots[d].color)) {
                        elementsToSelect.push(note2.dots[d])
                        addNoteToSelect(note2, selectableElements)
                        matchedCount++
                    }
                }
            }

            // Accidentals
            if (matchAccidental && note2.accidental && colorsMatch(note2.accidental.color)) {
                elementsToSelect.push(note2.accidental)
                addNoteToSelect(note2, selectableElements)
                matchedCount++
            }

            // Ties from note
            if (matchTie && note2.tieForward && colorsMatch(note2.tieForward.color)) {
                elementsToSelect.push(note2.tieForward)
                addNoteToSelect(note2, selectableElements)
                matchedCount++
            }
        }

        // Chord-level elements (select first note if these match)
        var firstNote = chord.notes.length > 0 ? chord.notes[0] : null

        // Stem
        if (matchStem && chord.stem && colorsMatch(chord.stem.color)) {
            elementsToSelect.push(chord.stem)
            if (firstNote) addNoteToSelect(firstNote, selectableElements)
            matchedCount++
        }

        // Hook
        if (matchHook && chord.hook && colorsMatch(chord.hook.color)) {
            elementsToSelect.push(chord.hook)
            if (firstNote) addNoteToSelect(firstNote, selectableElements)
            matchedCount++
        }

        // Beam
        if (matchBeam && chord.beam && colorsMatch(chord.beam.color)) {
            elementsToSelect.push(chord.beam)
            if (firstNote) addNoteToSelect(firstNote, selectableElements)
            matchedCount++
        }

        // Articulations
        if (matchArticulation && chord.articulations) {
            for (var a = 0; a < chord.articulations.length; a++) {
                if (colorsMatch(chord.articulations[a].color)) {
                    elementsToSelect.push(chord.articulations[a])
                    if (firstNote) addNoteToSelect(firstNote, selectableElements)
                    matchedCount++
                }
            }
        }
    }

    // Process segment annotations
    function processAnnotations(segment, track, elementsToSelect, selectableElements) {
        if (!segment.annotations) return
        for (var i = 0; i < segment.annotations.length; i++) {
            var anno = segment.annotations[i]
            if (anno.track === track) {
                checkElement(anno, elementsToSelect, selectableElements)
            }
        }
    }

    // Main function: select elements by colour
    function selectByColour() {
        if (!curScore) {
            statusLabel.text = qsTr("No score open!")
            return
        }

        var hasSelection = curScore.selection.elements.length > 0
        var elementsToSelect = []      // All matched elements (for counting)
        var selectableElements = []    // Elements that can actually be selected
        matchedCount = 0

        var targetInfo = matchAlphaCheck.checked ?
            getFullColorString() : targetColourHex.toLowerCase()
        console.log("Looking for colour: " + targetInfo)

        if (hasSelection && useSelectionCheck.checked) {
            // Search within current selection
            for (var i = 0; i < curScore.selection.elements.length; i++) {
                var el = curScore.selection.elements[i]
                checkElement(el, elementsToSelect, selectableElements)
            }
        } else {
            // Search entire score
            var cursor = curScore.newCursor()
            for (var staff = 0; staff < curScore.nstaves; staff++) {
                for (var voice = 0; voice < 4; voice++) {
                    cursor.staffIdx = staff
                    cursor.voice = voice
                    cursor.rewind(Cursor.SCORE_START)

                    while (cursor.segment) {
                        var track = staff * 4 + voice

                        if (cursor.element) {
                            if (cursor.element.type === Element.CHORD) {
                                processChord(cursor.element, elementsToSelect, selectableElements)
                            } else if (cursor.element.type === Element.REST && matchRest) {
                                if (colorsMatch(cursor.element.color)) {
                                    elementsToSelect.push(cursor.element)
                                    selectableElements.push(cursor.element)
                                    matchedCount++
                                }
                            }
                        }

                        // Check annotations (dynamics, lyrics, etc.)
                        processAnnotations(cursor.segment, track, elementsToSelect, selectableElements)

                        cursor.next()
                    }
                }
            }

            // Search spanners (slurs, hairpins, ottavas, pedals)
            if (matchSlur || matchHairpin || matchOttava || matchPedal) {
                var spanners = curScore.spanners
                for (var s in spanners) {
                    var spanner = spanners[s]
                    checkElement(spanner, elementsToSelect, selectableElements)
                }
            }
        }

        if (selectableElements.length > 0) {
            curScore.startCmd()
            curScore.selection.clear()
            for (var j = 0; j < selectableElements.length; j++) {
                curScore.selection.select(selectableElements[j], true)
            }
            curScore.endCmd()
            // Show both matched count and actually selected count
            if (matchedCount !== selectableElements.length) {
                statusLabel.text = qsTr("Found %1, selected %2 (some elements select via parent note)")
                    .arg(matchedCount).arg(selectableElements.length)
            } else {
                statusLabel.text = qsTr("Selected %1 element(s)").arg(matchedCount)
            }
        } else if (matchedCount > 0) {
            // Found elements but none could be selected
            statusLabel.text = qsTr("Found %1 element(s) but none can be selected directly").arg(matchedCount)
        } else {
            statusLabel.text = qsTr("No elements found with colour %1").arg(targetInfo)
        }
    }

    // Pick colour from selected element
    function pickColourFromSelection() {
        if (!curScore || curScore.selection.elements.length === 0) {
            statusLabel.text = qsTr("Please select an element first")
            return
        }

        var el = curScore.selection.elements[0]
        if (el.color !== undefined) {
            var colorInfo = parseColorString(el.color)
            targetColourHex = colorInfo.rgb
            targetAlpha = colorInfo.alpha
            colorInput.currentText = colorInfo.rgb
            alphaInput.currentText = colorInfo.alpha.toString()
            statusLabel.text = qsTr("Picked: RGB=%1, Alpha=%2").arg(colorInfo.rgb).arg(colorInfo.alpha)
        } else {
            statusLabel.text = qsTr("Selected element has no color property")
        }
    }

    // Get active element types description
    function getActiveTypesText() {
        var types = []
        if (matchNote) types.push("Note")
        if (matchStem) types.push("Stem")
        if (matchBeam) types.push("Beam")
        if (matchHook) types.push("Hook")
        if (matchNoteDot) types.push("Dot")
        if (matchSlur) types.push("Slur")
        if (matchTie) types.push("Tie")
        if (matchAccidental) types.push("Accid.")
        if (matchArticulation) types.push("Artic.")
        if (matchRest) types.push("Rest")
        if (matchLyrics) types.push("Lyrics")
        if (matchDynamic) types.push("Dyn.")
        if (matchHairpin) types.push("Hairpin")
        if (matchOttava) types.push("Ottava")
        if (matchPedal) types.push("Pedal")
        if (types.length === 0) return qsTr("None")
        if (types.length > 3) return types.slice(0, 3).join(", ") + "..."
        return types.join(", ")
    }

    // Boomwhackers colour palette
    property var colourPalette: [
        "#000000", "#e21c48", "#f26622", "#f99d1c",
        "#ffcc33", "#fff32b", "#bcd85f", "#62bc47",
        "#009c95", "#0071bb", "#5e50a1", "#cf3e96"
    ]

    Column {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        // Title
        StyledTextLabel {
            text: qsTr("Select Elements by Colour")
            font.bold: true
            font.pixelSize: 16
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Colour selection row (RGB)
        Row {
            spacing: 10

            StyledTextLabel {
                text: qsTr("RGB:")
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: colourPreview
                width: 40
                height: 28
                color: targetColourHex
                opacity: targetAlpha / 255.0
                border.color: ui.theme.strokeColor
                border.width: 1
                radius: 3

                Rectangle {
                    anchors.fill: parent
                    z: -1
                    color: "#ffffff"
                    radius: 3
                }
            }

            TextInputField {
                id: colorInput
                width: 100
                currentText: targetColourHex

                onTextChanged: function(newText) {
                    var hexPattern = /^#[0-9A-Fa-f]{6}$/
                    if (hexPattern.test(newText)) {
                        targetColourHex = newText.toLowerCase()
                    }
                }
            }

            FlatButton {
                text: qsTr("Pick")
                onClicked: pickColourFromSelection()
            }
        }

        // Alpha row
        Row {
            spacing: 10

            StyledTextLabel {
                text: qsTr("Alpha (0-255):")
                anchors.verticalCenter: parent.verticalCenter
            }

            TextInputField {
                id: alphaInput
                width: 60
                currentText: targetAlpha.toString()

                onTextChanged: function(newText) {
                    var val = parseInt(newText)
                    if (!isNaN(val) && val >= 0 && val <= 255) {
                        targetAlpha = val
                    }
                }
            }

            StyledTextLabel {
                text: qsTr("(255=opaque, 0=transparent)")
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.7
            }
        }

        // Element types row
        Row {
            spacing: 10

            StyledTextLabel {
                text: qsTr("Element Types:")
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledTextLabel {
                text: getActiveTypesText()
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.8
            }

            FlatButton {
                text: elementPanelVisible ? qsTr("Hide") : qsTr("Configure...")
                onClicked: elementPanelVisible = !elementPanelVisible
            }
        }

        // Element types panel (collapsible)
        Rectangle {
            id: elementTypesPanel
            width: parent.width
            height: elementPanelVisible ? 100 : 0
            visible: elementPanelVisible
            color: ui.theme.buttonColor
            border.color: ui.theme.strokeColor
            border.width: 1
            radius: 4
            clip: true

            Grid {
                anchors.fill: parent
                anchors.margins: 8
                columns: 5
                rowSpacing: 4
                columnSpacing: 4

                CheckBox { id: chkNote; text: "Note"; checked: matchNote; onClicked: { checked = !checked; matchNote = checked } }
                CheckBox { id: chkStem; text: "Stem"; checked: matchStem; onClicked: { checked = !checked; matchStem = checked } }
                CheckBox { id: chkBeam; text: "Beam"; checked: matchBeam; onClicked: { checked = !checked; matchBeam = checked } }
                CheckBox { id: chkHook; text: "Hook"; checked: matchHook; onClicked: { checked = !checked; matchHook = checked } }
                CheckBox { id: chkDot; text: "Dot"; checked: matchNoteDot; onClicked: { checked = !checked; matchNoteDot = checked } }
                CheckBox { id: chkSlur; text: "Slur"; checked: matchSlur; onClicked: { checked = !checked; matchSlur = checked } }
                CheckBox { id: chkTie; text: "Tie"; checked: matchTie; onClicked: { checked = !checked; matchTie = checked } }
                CheckBox { id: chkAccid; text: "Accid."; checked: matchAccidental; onClicked: { checked = !checked; matchAccidental = checked } }
                CheckBox { id: chkArtic; text: "Artic."; checked: matchArticulation; onClicked: { checked = !checked; matchArticulation = checked } }
                CheckBox { id: chkRest; text: "Rest"; checked: matchRest; onClicked: { checked = !checked; matchRest = checked } }
                CheckBox { id: chkLyrics; text: "Lyrics"; checked: matchLyrics; onClicked: { checked = !checked; matchLyrics = checked } }
                CheckBox { id: chkDyn; text: "Dynamic"; checked: matchDynamic; onClicked: { checked = !checked; matchDynamic = checked } }
                CheckBox { id: chkHairpin; text: "Hairpin"; checked: matchHairpin; onClicked: { checked = !checked; matchHairpin = checked } }
                CheckBox { id: chkOttava; text: "Ottava"; checked: matchOttava; onClicked: { checked = !checked; matchOttava = checked } }
                CheckBox { id: chkPedal; text: "Pedal"; checked: matchPedal; onClicked: { checked = !checked; matchPedal = checked } }
            }
        }

        // Common colours label
        StyledTextLabel {
            text: qsTr("Common Colours (Boomwhackers):")
        }

        // Colour palette grid
        Grid {
            id: paletteGrid
            columns: 6
            spacing: 6

            Repeater {
                model: colourPalette

                Rectangle {
                    width: 50
                    height: 32
                    color: modelData
                    border.color: targetColourHex.toLowerCase() === modelData.toLowerCase() ? "#000000" : ui.theme.strokeColor
                    border.width: targetColourHex.toLowerCase() === modelData.toLowerCase() ? 2 : 1
                    radius: 3

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            targetColourHex = modelData
                            colorInput.currentText = modelData
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        // Options
        Row {
            spacing: 20

            CheckBox {
                id: useSelectionCheck
                text: qsTr("Search in selection only")
                checked: false
                onClicked: checked = !checked
            }

            CheckBox {
                id: matchAlphaCheck
                text: qsTr("Match alpha")
                checked: false
                onClicked: checked = !checked
            }
        }

        // Status label
        StyledTextLabel {
            id: statusLabel
            text: qsTr("Click 'Select' to find elements with the specified colour")
            width: parent.width
            wrapMode: Text.WordWrap
        }

        // Spacer
        Item {
            width: 1
            height: 10
        }
    }

    // Buttons row (fixed at bottom)
    Row {
        id: buttonRow
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15
        anchors.rightMargin: 15
        spacing: 10

        FlatButton {
            text: qsTr("Select")
            accentButton: true
            onClicked: selectByColour()
        }

        FlatButton {
            text: qsTr("Close")
            onClicked: quit()
        }
    }
}
