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
    property var backgroundVolume: 40

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
            var path = fileDialog.fileUrl.toString();
            // remove prefixed "file:///"
            path = path.replace(/^(file:\/{2})/,"");
            // unescape html codes like '%23' for '#'
            var cleanPath = decodeURIComponent(path);

            generateLearningTracks(cleanPath);
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
            "id": partIdx, "selected": true, "volume": part.volume});
        }
    }

    // Set all parts to volume specified by vol
    // disable mute if enabled.
    function mixerVolAll(vol) {
        var part;
        for (var partIdx = 0; partIdx < curScore.parts.length; partIdx++) {
            mixerVolPart(vol, partIdx);
        }
    }

    // set the volume of a certain part to "vol"
    function mixerVolPart(vol, partIdx) {
        var part
        part = curScore.parts[partIdx];
        part.volume = vol;
        part.mute = false; 
    }

    function generateMp3File(baseName, partName) {
        partName = partName.replace(/<(?:.|\n)*?>/gm, '');
        var fileName = baseName + "-" + partName + ".mp3";
        console.log ( "Generating track: " + fileName);
        writeScore(curScore , fileName, "mp3" )
    }

    // Generates learning tracks to the destination folder.
    function generateLearningTracks(destination) {
        var baseName =  destination + '/' + curScore.name

        // set Volume of all parts to 100
        mixerVolAll(mainVolume)

        // export score as mp3 with all voices at normal
        generateMp3File(baseName, "All");

        // get number of all parts without piano
        // for every choir voice (eq. part) set all others to volume 50
        for (var i = 0; i < partModel.count; ++i)
        {
            if (!partModel.get(i).selected) continue;
            
            // all others to background volume
            mixerVolAll(backgroundVolume);
            // single choir voice to 100
            mixerVolPart(mainVolume, partModel.get(i).id)		

            generateMp3File(baseName, partModel.get(i).longName);
        }

        // when finished set all back to normal
        var part;
        for (var i = 0; i < partModel.count; ++i) {
            mixerVolPart(partModel.get(i).volume, partModel.get(i).id);
        }
    }

    onRun:
    {
        var expName;  // filename for export

        if (typeof curScore == 'undefined') { Qt.quit()}
        populatePartsModel();
        appDialog.open();		
    } // on run

}
