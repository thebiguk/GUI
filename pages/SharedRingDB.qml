// Copyright (c) 2018, The Monero Project
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of
//    conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice, this list
//    of conditions and the following disclaimer in the documentation and/or other
//    materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its contributors may be
//    used to endorse or promote products derived from this software without specific
//    prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

import "../components"
import moneroComponents.Clipboard 1.0

Rectangle {

    color: "transparent"

    Clipboard { id: clipboard }

    function validHex32(s) {
        if (s.length != 64)
            return false
        for (var i = 0; i < s.length; ++i)
            if ("0123456789abcdefABCDEF".indexOf(s[i]) == -1)
                return false
        return true
    }

    function validRing(str, relative) {
        var outs = str.split(" ");
        if (outs.length == 0)
            return false
        for (var i = 1; i < outs.length; ++i) {
            if (relative) {
                if (outs[i] <= 0)
                    return false
            }
            else {
                if (outs[i] <= outs[i-1])
                    return false
            }
        }
        return true
    }

    /* main layout */
    ColumnLayout {
        id: mainLayout
        anchors.margins: 40
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right

        spacing: 20
        property int labelWidth: 120
        property int editWidth: 400
        property int lineEditFontSize: 12

        MessageDialog {
            id: sharedRingDBDialog
            standardButtons: StandardButton.Ok
        }

        Text {
            text: qsTr("This page allows you to interact with the shared ring database.<br>" +
                       "This database is meant for use by Masari wallets as well as wallets from Masari clones which reuse Masari keys.") + translationManager.emptyString
            wrapMode: Text.Wrap
            Layout.fillWidth: true;
            color: Style.defaultFontColor
        }

        Text {
            textFormat: Text.RichText
            text: "<style type='text/css'>a {text-decoration: none; color: #4CB860; font-size: 14px;}</style>" +
                  "<font size='+2'>" + qsTr("Blackballed outputs") + "</font>" + "<font size='2'> (</font><a href='#'>" + qsTr("help") + "</a><font size='2'>)</font><br>" +
                  qsTr("This sets which outputs are known to be spent, and thus not to be used as privacy placeholders in ring signatures.<br>") +
                  qsTr("You should only have to load a file when you want to refresh the list. Manual adding/removing is possible if needed.") + translationManager.emptyString
            wrapMode: Text.Wrap
            Layout.fillWidth: true;
            onLinkActivated: {
                sharedRingDBDialog.title  = qsTr("Blackballed outputs") + translationManager.emptyString;
                sharedRingDBDialog.text = qsTr(
                    "In order to obscure which inputs in a Masari transaction are being spent, a third party should not be able " +
                    "to tell which inputs in a ring are already known to be spent. Being able to do so would weaken the protection " +
                    "afforded by ring signatures. If all but one of the inputs are known to be already spent, then the input being " +
                    "actually spent becomes apparent, thereby nullifying the effect of ring signatures, one of the three main layers " +
                    "of privacy protection Masari uses.<br>" +
                    "To help transactions avoid those inputs, a list of known spent ones can be used to avoid using them in new " +
                    "transactions. Such a list is maintained by the Masari project and is available on the getmasari.org website, " +
                    "and you can import this list here.<br>" +
                    "Alternatively, you can scan the blockchain (and the blockchain of key-reusing Masari clones) yourself " +
                    "using the masari-blockchain-blackball tool to create a list of known spent outputs.<br>"
                )
                sharedRingDBDialog.icon = StandardIcon.Information
                sharedRingDBDialog.open()
            }
            color: Style.defaultFontColor
        }

        RowLayout {
            id: loadBlackballFileRow
            anchors.topMargin: 17
            anchors.left: parent.left
            anchors.right: parent.right

            FileDialog {
                id: loadBlackballFileDialog
                title: qsTr("Please choose a file to load blackballed outputs from") + translationManager.emptyString;
                folder: "file://"
                nameFilters: [ "*"]

                onAccepted: {
                    loadBlackballFileLine.text = walletManager.urlToLocalPath(loadBlackballFileDialog.fileUrl)
                }
            }

            StandardButton {
                id: selectBlackballFileButton
                anchors.rightMargin: 17 * scaleRatio
                text: qsTr("Select") + translationManager.emptyString
                enabled: true
                small: true
                onClicked: {
                  loadBlackballFileDialog.open()
                }
            }

            LineEdit {
                id: loadBlackballFileLine
                placeholderText: qsTr("Filename with outputs to blackball") + translationManager.emptyString;
                readOnly: false
                Layout.fillWidth: true

                IconButton {
                    imageSource: "../images/copyToClipboard.png"
                    onClicked: {
                        if (loadBlackballFileLine.text.length > 0) {
                            clipboard.setText(loadBlackballFileLine.text)
                        }
                    }
                }
            }

            StandardButton {
                id: loadBlackballFileButton
                text: qsTr("Load") + translationManager.emptyString
                small: true
                enabled: !!appWindow.currentWallet
                onClicked: appWindow.currentWallet.blackballOutputs(walletManager.urlToLocalPath(loadBlackballFileDialog.fileUrl), true)
            }
        }

        Label {
            fontSize: 14
            text: qsTr("Or manually blackball or unblackball a single output:") + translationManager.emptyString
            width: mainLayout.labelWidth
        }

        RowLayout {
            LineEdit {
                id: blackballOutputLine
                fontSize: mainLayout.lineEditFontSize
                placeholderText: qsTr("Paste output public key") + translationManager.emptyString
                readOnly: false
                width: mainLayout.editWidth
                Layout.fillWidth: true

                IconButton {
                    imageSource: "../images/copyToClipboard.png"
                    onClicked: {
                        if (blackballOutputLine.text.length > 0) {
                            clipboard.setText(blackballOutputLine.text)
                        }
                    }
                }
            }

            StandardButton {
                id: blackballButton
                text: qsTr("Blackball") + translationManager.emptyString
                small: true
                enabled: !!appWindow.currentWallet && validHex32(blackballOutputLine.text)
                onClicked: appWindow.currentWallet.blackballOutput(blackballOutputLine.text)
            }

            StandardButton {
                id: unblackballButton
                anchors.right: parent.right
                text: qsTr("Unblackball") + translationManager.emptyString
                small: true
                enabled: !!appWindow.currentWallet && validHex32(blackballOutputLine.text)
                onClicked: appWindow.currentWallet.unblackballOutput(blackballOutputLine.text)
            }
        }

        Text {
            textFormat: Text.RichText
            text: "<style type='text/css'>a {text-decoration: none; color: #4CB860; font-size: 14px;}</style>" +
                  "<font size='+2'>" + qsTr("Rings") + "</font>" + "<font size='2'> (</font><a href='#'>" + qsTr("help") + "</a><font size='2'>)</font><br>" +
                  qsTr("This records rings used by outputs spent on Masari on a key reusing chain, so that the same ring may be reused to avoid privacy issues.") + translationManager.emptyString
            wrapMode: Text.Wrap
            Layout.fillWidth: true;
            onLinkActivated: {
                sharedRingDBDialog.title  = qsTr("Rings") + translationManager.emptyString;
                sharedRingDBDialog.text = qsTr(
                    "In order to avoid nullifying the protection afforded by Masari's ring signatures, an output should not " +
                    "be spent with different rings on different blockchains. While this is normally not a concern, it can become one " +
                    "when a key-reusing Masari clone allows you do spend existing outputs. In this case, you need to ensure this " +
                    "existing outputs uses the same ring on both chains.<br>" +
                    "This will be done automatically by Masari and any key-reusing software which is not trying to actively strip " +
                    "you of your privacy.<br>" +
                    "If you are using a key-reusing Masari clone too, and this clone does not include this protection, you can still " +
                    "ensure your transactions are protected by spending on the clone first, then manually adding the ring on this page, " +
                    "which allows you to then spend your Masari safely.<br>" +
                    "If you do not use a key-reusing Masari clone without these safety features, then you do not need to do anything " +
                    "as it is all automated.<br>"
                )
                sharedRingDBDialog.icon = StandardIcon.Information
                sharedRingDBDialog.open()
            }
            color: Style.defaultFontColor
        }

        RowLayout {
            LineEdit {
                id: keyImageLine
                fontSize: mainLayout.lineEditFontSize
                placeholderText: qsTr("Paste key image") + translationManager.emptyString
                readOnly: false
                width: mainLayout.editWidth
                Layout.fillWidth: true

                IconButton {
                    imageSource: "../images/copyToClipboard.png"
                    onClicked: {
                        if (keyImageLine.text.length > 0) {
                            clipboard.setText(keyImageLine.text)
                        }
                    }
                }
            }
        }

        RowLayout {
            StandardButton {
                id: getRingButton
                text: qsTr("Get Ring") + translationManager.emptyString
                small: true
                enabled: !!appWindow.currentWallet && validHex32(keyImageLine.text)
                onClicked: {
                    var ring = appWindow.currentWallet.getRing(keyImageLine.text)
                    if (ring === "")
                    {
                        getRingLine.text = qsTr("No ring found");
                    }
                    else
                    {
                        getRingLine.text = ring;
                    }
                }
            }
            LineEdit {
                id: getRingLine
                fontSize: mainLayout.lineEditFontSize
                placeholderText: qsTr("") + translationManager.emptyString
                readOnly: true
                width: mainLayout.editWidth
                Layout.fillWidth: true

                IconButton {
                    imageSource: "../images/copyToClipboard.png"
                    onClicked: {
                        if (getRingLine.text.length > 0) {
                            clipboard.setText(getRingLine.text)
                        }
                    }
                }
            }
        }

        RowLayout {
            CheckBox {
                id: setRingRelative
                checked: true
                text: qsTr("Relative") + translationManager.emptyString
                checkedIcon: "../images/checkedBlackIcon.png"
                uncheckedIcon: "../images/uncheckedIcon.png"
            }
            LineEdit {
                id: setRingLine
                fontSize: mainLayout.lineEditFontSize
                placeholderText: qsTr("") + translationManager.emptyString
                readOnly: false
                width: mainLayout.editWidth

                IconButton {
                    imageSource: "../images/copyToClipboard.png"
                    onClicked: {
                        if (getRingLine.text.length > 0) {
                            clipboard.setText(getRingLine.text)
                        }
                    }
                }
            }
            StandardButton {
                id: setRingButton
                text: qsTr("Set Ring") + translationManager.emptyString
                enabled: !!appWindow.currentWallet && validHex32(keyImageLine.text) && validRing(setRingLine.text.trim(), setRingRelative.checked)
                onClicked: {
                    var outs = setRingLine.text.trim()
                    appWindow.currentWallet.setRing(keyImageLine.text, outs, setRingRelative.checked)
                }
            }
        }

        CheckBox {
            id: segregatePreForkOutputs
            checked: persistentSettings.segregatePreForkOutputs
            text: qsTr("I intend to spend on key-reusing fork(s)") + translationManager.emptyString
            checkedIcon: "../images/checkedBlackIcon.png"
            uncheckedIcon: "../images/uncheckedIcon.png"
            onClicked: {
                persistentSettings.segregatePreForkOutputs = segregatePreForkOutputs.checked
                if (appWindow.currentWallet) {
                    appWindow.currentWallet.segregatePreForkOutputs(segregatePreForkOutputs.checked)
                }
            }
        }
        CheckBox {
            id: keyReuseMitigation2
            checked: persistentSettings.keyReuseMitigation2
            text: qsTr("I might want to spend on key-reusing fork(s)") + translationManager.emptyString
            checkedIcon: "../images/checkedBlackIcon.png"
            uncheckedIcon: "../images/uncheckedIcon.png"
            onClicked: {
                persistentSettings.keyReuseMitigation2 = keyReuseMitigation2.checked
                if (appWindow.currentWallet) {
                    appWindow.currentWallet.keyReuseMitigation2(keyReuseMitigation2.checked)
                }
            }
        }
        RowLayout {
            id: segregationHeightRow
            anchors.topMargin: 17
            anchors.left: parent.left
            anchors.right: parent.right

            Label {
                id: segregationHeightLabel
                fontSize: 14
                text: qsTr("Segregation height:") + translationManager.emptyString
            }
            LineEdit {
                id: segregationHeightLine
                readOnly: false
                Layout.fillWidth: true
                validator: IntValidator { bottom: 0 }
                onEditingFinished: {
                    persistentSettings.segregationHeight = segregationHeightLine.text
                    if (appWindow.currentWallet) {
                        appWindow.currentWallet.segregationHeight(segregationHeightLine.text)
                    }
                }
            }
        }

    }

    function onPageCompleted() {
        console.log("RingDB page loaded");
        appWindow.currentWallet.segregatePreForkOutputs(persistentSettings.segregatePreForkOutputs)
        appWindow.currentWallet.segregationHeight(persistentSettings.segregationHeight)
        segregationHeightLine.text = persistentSettings.segregationHeight
        appWindow.currentWallet.keyReuseMitigation2(persistentSettings.keyReuseMitigation2)
    }

}
