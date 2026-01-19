//=============================================================================
//  Select Notes by Colour
//
//  Select all notes of a specified colour in the score or within selection.
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
    version: "1.1"
    title: qsTr("Select by Colour")
    description: qsTr("Select all notes of a specified colour in the score or selection")
    categoryCode: "composing-arranging-tools"
    pluginType: "dialog"
    requiresScore: true

    width: 440
    height: 400

    // Default target colour (black, fully opaque)
    property string targetColourHex: "#000000"
    property int targetAlpha: 255
    property int matchedCount: 0

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
            // #aarrggbb format
            var alpha = parseInt(s.substring(1, 3), 16)
            var rgb = "#" + s.substring(3)
            return {rgb: rgb, alpha: alpha}
        } else if (s.length === 7 && s.charAt(0) === '#') {
            // #rrggbb format
            return {rgb: s, alpha: 255}
        }
        return {rgb: "#000000", alpha: 255}
    }

    // Compare colours
    function colorsMatch(noteColor) {
        var noteColorInfo = parseColorString(noteColor)
        var targetRgb = targetColourHex.toLowerCase()

        if (noteColorInfo.rgb !== targetRgb) {
            return false
        }

        // If "Match alpha" is checked, also compare alpha
        if (matchAlphaCheck.checked) {
            return noteColorInfo.alpha === targetAlpha
        }

        return true
    }

    // Main function: select notes by colour
    function selectNotesByColour() {
        if (!curScore) {
            statusLabel.text = qsTr("No score open!")
            return
        }

        var hasSelection = curScore.selection.elements.length > 0
        var elementsToSelect = []
        matchedCount = 0

        var targetInfo = matchAlphaCheck.checked ?
            getFullColorString() : targetColourHex.toLowerCase()
        console.log("Looking for colour: " + targetInfo)

        if (hasSelection && useSelectionCheck.checked) {
            for (var i = 0; i < curScore.selection.elements.length; i++) {
                var el = curScore.selection.elements[i]
                if (el.type === Element.NOTE) {
                    if (colorsMatch(el.color)) {
                        elementsToSelect.push(el)
                        matchedCount++
                    }
                }
            }
        } else {
            var cursor = curScore.newCursor()
            for (var staff = 0; staff < curScore.nstaves; staff++) {
                for (var voice = 0; voice < 4; voice++) {
                    cursor.staffIdx = staff
                    cursor.voice = voice
                    cursor.rewind(Cursor.SCORE_START)

                    while (cursor.segment) {
                        if (cursor.element && cursor.element.type === Element.CHORD) {
                            var chord = cursor.element
                            for (var n = 0; n < chord.notes.length; n++) {
                                var note = chord.notes[n]
                                if (colorsMatch(note.color)) {
                                    elementsToSelect.push(note)
                                    matchedCount++
                                }
                            }
                        }
                        cursor.next()
                    }
                }
            }
        }

        if (elementsToSelect.length > 0) {
            curScore.startCmd()
            curScore.selection.clear()
            for (var j = 0; j < elementsToSelect.length; j++) {
                curScore.selection.select(elementsToSelect[j], true)
            }
            curScore.endCmd()
            statusLabel.text = qsTr("Selected %1 note(s)").arg(matchedCount)
        } else {
            statusLabel.text = qsTr("No notes found with colour %1").arg(targetInfo)
        }
    }

    // Pick colour from selected note
    function pickColourFromSelection() {
        if (!curScore || curScore.selection.elements.length === 0) {
            statusLabel.text = qsTr("Please select a note first")
            return
        }

        for (var i = 0; i < curScore.selection.elements.length; i++) {
            var el = curScore.selection.elements[i]
            if (el.type === Element.NOTE) {
                var colorInfo = parseColorString(el.color)
                targetColourHex = colorInfo.rgb
                targetAlpha = colorInfo.alpha
                colorInput.currentText = colorInfo.rgb
                alphaInput.currentText = colorInfo.alpha.toString()
                statusLabel.text = qsTr("Picked: RGB=%1, Alpha=%2").arg(colorInfo.rgb).arg(colorInfo.alpha)
                return
            }
        }
        statusLabel.text = qsTr("No note in selection")
    }

    // Boomwhackers colour palette
    property var colourPalette: [
        "#000000", "#e21c48", "#f26622", "#f99d1c",
        "#ffcc33", "#fff32b", "#bcd85f", "#62bc47",
        "#009c95", "#0071bb", "#5e50a1", "#cf3e96"
    ]

    Item {
        id: window
        anchors.fill: parent

        // Title
        StyledTextLabel {
            id: titleLabel
            text: qsTr("Select Notes by Colour")
            font.bold: true
            font.pixelSize: 16
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 15
        }

        // Colour selection row (RGB)
        Row {
            id: colourRow
            anchors.top: titleLabel.bottom
            anchors.left: parent.left
            anchors.topMargin: 15
            anchors.leftMargin: 15
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

                // Checkerboard background to show transparency
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
                text: qsTr("Pick from Note")
                onClicked: pickColourFromSelection()
            }
        }

        // Alpha row
        Row {
            id: alphaRow
            anchors.top: colourRow.bottom
            anchors.left: parent.left
            anchors.topMargin: 10
            anchors.leftMargin: 15
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
                text: qsTr("(255 = opaque, 0 = transparent)")
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.7
            }
        }

        // Common colours label
        StyledTextLabel {
            id: paletteLabel
            text: qsTr("Common Colours (Boomwhackers):")
            anchors.top: alphaRow.bottom
            anchors.left: parent.left
            anchors.topMargin: 15
            anchors.leftMargin: 15
        }

        // Colour palette grid
        Grid {
            id: paletteGrid
            anchors.top: paletteLabel.bottom
            anchors.left: parent.left
            anchors.topMargin: 8
            anchors.leftMargin: 15
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
            id: optionsRow
            anchors.top: paletteGrid.bottom
            anchors.left: parent.left
            anchors.topMargin: 15
            anchors.leftMargin: 15
            spacing: 20

            CheckBox {
                id: useSelectionCheck
                text: qsTr("Search in selection only")
                checked: false
            }

            CheckBox {
                id: matchAlphaCheck
                text: qsTr("Match alpha")
                checked: false
            }
        }

        // Status label
        StyledTextLabel {
            id: statusLabel
            text: qsTr("Click 'Select' to find notes with the specified colour")
            anchors.top: optionsRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 15
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            wrapMode: Text.WordWrap
        }

        // Buttons row
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
                onClicked: selectNotesByColour()
            }

            FlatButton {
                text: qsTr("Close")
                onClicked: quit()
            }
        }
    }
}
