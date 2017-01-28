import QtQuick 2.2
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import MuseScore 1.0


MuseScore {
    version:  "1.0"
    description: "Exports score as mp3 learning track for individual parts."
    menuPath: "Plugins.Choir Rehearsal Export"

    property var mainVolume: 90
    property var backgroundVolume: 30

    ListModel {
        id: partModel
    }

    Dialog {
        id : appDialog
        title : qsTr("Export learning tracks")
        width: 400

        ColumnLayout {
            id: mainLayout
            width: appDialog.width - 20
            Label {
                text: qsTr("Select which parts should be exported:")
            }

            ScrollView {
                Layout.bottomMargin: 20
                Layout.fillWidth: true
                ListView {
                    id: listView
                    model: partModel
                    delegate: RowLayout {
                        CheckBox {
                            id: part
                            property var partId: id
                            text: longName
                            checked: selected
                            onClicked: {
                                partModel.setProperty(id, "selected", checked)
                            }
                        }
                    }
                }
            }
        }
        standardButtons: StandardButton.Cancel | StandardButton.Ok
        onAccepted : fileDialog.open();
        onRejected : Qt.quit();
    }

    // Selects folder to save the learning tracks to.
    FileDialog {
        id: fileDialog
        title: qsTr("Please choose a folder")
        selectFolder: true
        onAccepted: {
            String.prototype.startsWith = function(str) 
            {return (this.match("^"+str)==str)}

            var fileUrl = fileDialog.fileUrl.toString();
            if (fileUrl.startsWith("file://"))
            {
                generateLearningTracks(fileUrl.substring(7))
            }
            else
            {
                console.log("Selected non-local file, aborting.")
            }
            Qt.quit()
        }
        onRejected: {
            Qt.quit()
        }
    }

    // Populates the parts model from the current score.
    function populatePartsModel() {
        partModel.clear(); 
        var part;
        for (var partIdx = 0; partIdx < curScore.parts.length; partIdx++)
        {
            part = curScore.parts[partIdx];
            partModel.append({"shortName": part.shortName, "longName": part.longName,
            "id": partIdx, "selected": true});
        }
    }

    // Set all parts to volume specified by vol
    // disable mute if enabled.
    function mixerVolAll(vol) {
        var part;
        for (var partIdx = 0; partIdx < curScore.parts.length; partIdx++) {
            part = curScore.parts[partIdx];
            part.volume = vol;
            part.mute = false ; 
        }
    }

    // set the volume of a certain part to "vol"
    function mixerVolPart(vol, partIdx) {
        var part
        part = curScore.parts[partIdx];
        part.volume = vol;
        part.mute = false; 
    }

    // Get a Name/Volume pattern to be used in the export filename
    // e.g. S.50_A.100_T.50_B.50
    function namesVol(maxPart) {
        var part;
        var retName;
        retName = "";
        for (var partIdx = 0; partIdx < maxPart ; partIdx++)
        {
            part = curScore.parts[partIdx];
            retName += "_" + part.shortName + part.volume;
        }

        return retName;
    }

    // Generates learning tracks to the destination folder.
    function generateLearningTracks(destination) {
        // set Volume of all parts to 100
        mixerVolAll(mainVolume)

        for(var i = 0; i < partModel.count; ++i) {
            console.log(partModel.get(i).longName + " - " + partModel.get(i).selected);
        }

        // export score as mp3 with all voices at normal
        var expName =  destination + '/' + curScore.name 
        expName += ".mp3"
        console.log ( "createfile: " + expName);
        writeScore(curScore , expName, "mp3" )


        // get number of all parts without piano
        // for every choir voice (eq. part) set all others to volume 50
        for (var partIdx = 0; partIdx < 0; partIdx++)
        {
            // all others to 50
            mixerVolAll(50)
            // single choir voice to 100
            mixerVolPart(100,partIdx)		

            expName =  destination + curScore.name 
            expName += namesVol(maxPart) + ".mp3"
            console.log ( "createfile: " + expName);
            writeScore(curScore , expName, "mp3" )
        }

        // when finished set all back to normal
        mixerVolAll(100)
    }

    onRun:
    {
        var expName;  // filename for export

        if (typeof curScore == 'undefined') { Qt.quit()}
        populatePartsModel();
        appDialog.open();		
    } // on run

}
