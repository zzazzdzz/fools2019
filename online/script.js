var reader = new FileReader();
var gameboy = null;

function cout(x){
    console.log(x);
}

reader.onload = function(e) {
    document.getElementById('intro').style.display = 'none';
    document.getElementById('cv').style.display = '';
    document.body.style.textAlign = 'center';
    gameboy = new GameBoyCore(document.getElementById('cv'), reader.result);
    gameboy.openMBC = getSAV;
    gameboy.openRTC = undefined;
    gameboy.start();
    gameboy.stopEmulator &= 1;
    var dateObj = new Date();
    gameboy.firstIteration = dateObj.getTime();
    gameboy.iterations = 0;
    gbRunInterval = setInterval(function(){
        gameboy.run();
    }, 8);
    document.getElementById('cv').getContext('2d').imageSmoothingEnabled = false;
};

var keyZones = [
    ["right", [39]],
    ["left", [37]],
    ["up", [38]],
    ["down", [40]],
    ["a", [90]],
    ["b", [83, 88]],
    ["select", [32]],
    ["start", [13]]
];

function matchKey(key){
    return ["right", "left", "up", "down", "a", "b", "select", "start"].indexOf(key);
}

window.onkeyup = function(e){
    var kk = e.keyCode;
    for (var i=0; i<keyZones.length; i++){
        var type = keyZones[i][0];
        if (keyZones[i][1].indexOf(kk) != -1){
            gameboy.JoyPadEvent(matchKey(type), false);
        }
    }
};
window.onkeydown = function(e){
    var kk = e.keyCode;
    for (var i=0; i<keyZones.length; i++){
        var type = keyZones[i][0];
        if (keyZones[i][1].indexOf(kk) != -1){
            gameboy.JoyPadEvent(matchKey(type), true);
        }
    }
};

function getSAV(){
    return B64_SRAM;
}