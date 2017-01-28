import QtQuick 2.2
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import MuseScore 1.0


MuseScore {
    version:  "1.0"
    description: "Exports score as mp3 learning track for individual parts."
    menuPath: "Plugins.Choir Rehearsal Export"

    ListModel {
        id: partModel
    }

    Dialog {
        id : appDialog
        title : qsTr("Export learning tracks")
        width : 470
        height: mainLayout.height

        GridLayout {
            id: mainLayout
            anchors.fill: parent
            columns: 1

            ListView {
                id: listView
                model: partModel
                Layout.minimumHeight: 100
                Layout.bottomMargin: 20
                delegate: CheckBox {
                    id: part
                    text: longName
                }
            }
        }
        standardButtons: StandardButton.Cancel | StandardButton.Ok
        onAccepted : fileDialog.open();
        onRejected : Qt.quit();
    }

    // Select folder to save the learning tracks.
    FileDialog {
        id: fileDialog
        title: "Please choose a folder"
        selectFolder: true
        onAccepted: {
            console.log("You chose: " + fileDialog.fileUrls)
            Qt.quit()
        }
        onRejected: {
            Qt.quit()
        }
    }

    function populatePartsModel() {
        partModel.clear(); 
        var part;
        for (var partIdx = 0; partIdx < curScore.parts.length; partIdx++)
        {
            part = curScore.parts[partIdx];
            partModel.append({"shortName": part.shortName, "longName": part.longName,
            "id": partIdx});
        }
    }

    // Set all parts to volume specified by vol
    // disable mute if enabled.
    function mixerVolAll(vol)
    {
        var part;
        for (var partIdx = 0; partIdx < curScore.parts.length; partIdx++)
        {
            part = curScore.parts[partIdx];
            part.volume = vol;
            part.mute = false ; 
        }
    }

    // set the volume of a certain part to "vol"
    function mixerVolPart(vol, partIdx)
    {
        var part
        part = curScore.parts[partIdx];
        part.volume = vol;
        part.mute = false; 
    }

    // Get a Name/Volume pattern to be used in the export filename
    // e.g. S.50_A.100_T.50_B.50
    function namesVol( maxPart )
    {
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

    onRun:
    {
        var expName;  // filename for export

        if (typeof curScore == 'undefined') { Qt.quit()}
        populatePartsModel();
        appDialog.open();		

        console.log("parts: " + curScore.parts.length);

        // set Volume of all parts to 100
        mixerVolAll(100)

        // export score as mp3 with all voices at normal
        //expName =  "D:/" + curScore.name 
        //expName += ".mp3"
        //console.log ( "createfile: " + expName);
        //writeScore(curScore , expName, "mp3" )


        // get number of all parts without piano
        // for every choir voice (eq. part) set all others to volume 50
        for (var partIdx = 0; partIdx < 0; partIdx++)
        {
            // all others to 50
            mixerVolAll(50)
            // single choir voice to 100
            mixerVolPart(100,partIdx)		

            expName =  "D:/" + curScore.name 
            expName += namesVol(maxPart) + ".mp3"
            console.log ( "createfile: " + expName);
            writeScore(curScore , expName, "mp3" )
        }

        // when finished set all back to normal
        mixerVolAll(100)
        Qt.quit()
    } // on run

}
