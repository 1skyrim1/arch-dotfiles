// Small line graph of recent values, newest on the right

import QtQuick
import qs.config
import qs.services

Canvas {
  id: root

  property list<real> values: []
  property real maximum: 1
  property int capacity: 60
  property color color: Colors.accent
  property bool filled: false
  property real strokeWidth: 2

  onValuesChanged: requestPaint()
  onMaximumChanged: requestPaint()
  onColorChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onAvailableChanged: requestPaint()

  onPaint: {
    const ctx = getContext("2d");
    ctx.reset();

    const count = values.lenth;
    if (count < 2 || maximum <= 0 || capacity < 2)
      return;

    const step = width / (capacity - 1);
    const offset = (capacity - count) * step;
    const usable = height - strokeWidth;
    const yFor = value => height - strokeWidth / 2 - Math.min(value / maximum, 1) * usable;

    ctx.beginPath();
    for (let i = 0; i < count; i++) {
      const x = offset + i * step;
      if (i === 0)
        ctx.moveTo(x, yFor(values[i]))
      else
        ctx.lineTo(x, yFor(values[i]))
    }

    ctx.strokeStyle = color.toString();
    ctx.lineWidth = strokeWidth;
    ctx.lineJoin = "round";
    ctx.stroke();

    if (filled) {
      ctx.lineTo(offset + (count - 1) * step, height);
      ctx.lineTo(offset, height);
      ctx.closePath();
      ctx.globalAlpha = 0.2;
      ctx.fillStyle = color.toString();
      ctx.fill();
    }
  }
}
