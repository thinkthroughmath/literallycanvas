{Tool} = require './base'
{createShape, shapeToJSON, JSONToShape} = require '../core/shapes'

# TODO: Put this in utils
getIsPointInBox = (point, box) ->
  if point.x < box.x then return false
  if point.y < box.y then return false
  if point.x > box.x + box.width then return false
  if point.y > box.y + box.height then return false
  return true

module.exports = class Picker extends Tool

  name: 'Picker'
  iconName: 'eyedropper'

  constructor: (lc) ->
    @picker = document.createElement('canvas')
    @picker.style['background-color'] = 'transparent'
    @pickerCtx = @picker.getContext('2d')
    # lc.containerEl.appendChild(@picker) # for peeking at it
    console.log 'new picker tool'

  drawPickerCanvas: (lc, shapes) ->
    console.log shapes
    @picker.width = lc.canvas.width
    @picker.height = lc.canvas.height
    @pickerCtx.clearRect(0, 0, @picker.width, @picker.height)
    lc.draw(shapes, @pickerCtx)

  intToHex: (i) ->
    "000000#{parseInt i, 16}".slice(-6)

  didBecomeActive: (lc) ->
    @drawPickerCanvas lc, lc.shapes.map (shape, index) =>
      shape.createWithColor?("##{@intToHex(index)}") || shape

  getPixel: (x, y, lc, ctx) ->
    p = lc.drawingCoordsToClientCoords x, y
    pixel = ctx.getImageData(p.x, p.y, 1, 1).data
    if pixel[3]
      # ToDo: this better.
      rStr = "00#{parseInt(pixel[0], 16)}".slice -2
      gStr = "00#{parseInt(pixel[1], 16)}".slice -2
      bStr = "00#{parseInt(pixel[2], 16)}".slice -2
      parseInt "#{rStr}#{gStr}#{bStr}", 10
    else
      null

  selectShape: (x, y, lc) ->
    @didDrag = false
    @dragAction = 'none'

    console.log "Set current shape..."

    @currentShape = lc.shapes[@getPixel(x, y, lc, @pickerCtx)]

    if @currentShape?
      console.log 'current shape is set!'
      lc.setShapesInProgress([createShape('SelectionBox', {shape: @currentShape, '#fff'})])

      br = @currentShape.getBoundingRect(lc.ctx)
      point = {x, y}
      if getIsPointInBox(point, br)
        console.log 'point in box!'
        @dragAction = 'move'

      @initialShapeBoundingRect = br
      @dragOffset = {
        x: x - @initialShapeBoundingRect.x,
        y: y - @initialShapeBoundingRect.y
      }
      lc.repaintLayer('main')

  begin: (x, y, lc) ->
    @selectShape(x, y, lc)

  continue: (x, y, lc) ->
    console.log "continue"
    # drag shape
    # when 'move'
    if @currentShape?
      @currentShape.x = x - @dragOffset.x
      @currentShape.y = y - @dragOffset.y
      @didDrag = true

    lc.repaintLayer('main')

  end: (x, y, lc) ->
    lc.setShapesInProgress([@currentShape])
    lc.repaintLayer('main')

