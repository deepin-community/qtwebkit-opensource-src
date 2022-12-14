(function() {

var MultiplyStage = Utilities.createSubclass(Stage,
    function()
    {
        Stage.call(this);
        this.tiles = [];
        this._offsetIndex = 0;
    }, {

    initialize: function(benchmark, options)
    {
        Stage.prototype.initialize.call(this, benchmark, options);
        var tileSize = Math.round(this.size.height / 20);

        // Fill the scene with elements
        var x = Math.round((this.size.width - tileSize) / 2);
        var y = Math.round((this.size.height - tileSize) / 2);
        var tileStride = tileSize;
        var direction = 0;
        var spiralCounter = 2;
        var nextIndex = 1;
        var maxSide = Math.floor(this.size.height / tileStride);
        var centerSpiralCount = maxSide * maxSide;
        for (var i = 0; i < centerSpiralCount; ++i) {
            this._addTile(x, y, tileSize, i % 360);

            if (i == nextIndex) {
                direction = (direction + 1) % 4;
                spiralCounter++;
                nextIndex += spiralCounter >> 1;
            }
            if (direction == 0)
                x += tileStride;
            else if (direction == 1)
                y -= tileStride;
            else if (direction == 2)
                x -= tileStride;
            else
                y += tileStride;
        }

        centerSpiralCount = maxSide * (maxSide + (maxSide & 1));
        for (var i = 0; i < centerSpiralCount; ++i) {
            var sideX = x + Math.floor(Math.floor(i / maxSide) / 2) * tileStride;
            var sideY = y - tileStride * (i % maxSide);

            if (Math.floor(i / maxSide) % 2 == 1)
                sideX = this.width - sideX - tileSize + 1;
            this._addTile(sideX, sideY, tileSize, (6 * i) % 360);
        }
    },

    _addTile: function(x, y, tileSize, rotateDeg)
    {
        var tile = Utilities.createElement("div", { class: "div-" + Stage.randomInt(0,6) }, this.element);
        var halfTileSize = tileSize / 2;
        tile.style.left = x + 'px';
        tile.style.top = y + 'px';
        tile.style.width = tileSize + 'px';
        tile.style.height = tileSize + 'px';

        var distance = 1.5 / tileSize * this.size.multiply(0.5).subtract(new Point(x + halfTileSize, y + halfTileSize)).length();

        this.tiles.push({
            element: tile,
            rotate: rotateDeg,
            step: Math.max(1, distance / 4),
            distance: distance,
            active: false
        });
    },

    complexity: function()
    {
        return this._offsetIndex;
    },

    tune: function(count)
    {
        this._offsetIndex = Math.max(0, Math.min(this._offsetIndex + count, this.tiles.length));
    },

    animate: function()
    {
        var distanceFactor = 1 / Math.sqrt(this._offsetIndex);

        var progress = this._benchmark.timestamp % 10000 / 10000;
        var bounceProgress = Math.sin(2 * Math.abs( 0.5 - progress));
        var l = Utilities.lerp(bounceProgress, 20, 50);
        var hslPrefix = "hsla(" + Utilities.lerp(progress, 0, 360) + ",100%,";

        for (var i = 0; i < this._offsetIndex; ++i) {
            var tile = this.tiles[i];
            tile.active = true;
            tile.rotate += tile.step;
            tile.element.style.transform = "rotate(" + tile.rotate + "deg)";

            var influence = 1 - (tile.distance * distanceFactor);
            tile.element.style.backgroundColor = hslPrefix + l * Math.tan(influence / 1.25) + "%," + influence + ")";
        }

        for (var i = this._offsetIndex; i < this.tiles.length && this.tiles[i].active; ++i) {
            this.tiles[i].active = false;
            this.tiles[i].element.style.backgroundColor = "";
        }
    }
});

var MultiplyBenchmark = Utilities.createSubclass(Benchmark,
    function(options)
    {
        Benchmark.call(this, new MultiplyStage(), options);
    }
);

window.benchmarkClass = MultiplyBenchmark;

}());
