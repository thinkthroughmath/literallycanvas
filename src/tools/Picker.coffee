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
  usesSimpleAPI: false

  constructor: (lc) ->
    @picker = document.createElement('canvas')
    @picker.style['background-color'] = 'transparent'
    @pickerCtx = @picker.getContext('2d')

  didBecomeActive: (lc) ->
    pickerUnsubscribeFuncs = []
    @pickerUnsubscribe = =>
      for func in pickerUnsubscribeFuncs
        func()

    @_drawPickerCanvas lc, lc.shapes.map (shape, index) =>
      shape.createWithColor?("##{@_intToHex(index)}") || shape

    @isDragging = false
    @currentShape = null
    @didDrag = false

    onDown = ({x, y}) =>
      shapeIndex = @_getPixel(x, y, lc, @pickerCtx)
      @currentShape = lc.shapes[shapeIndex]
      if @currentShape?
        lc.trigger 'lc-shape-selected', shapeToJSON(@currentShape)

        @initialShapeBoundingRect = @currentShape.getBoundingRect(lc.ctx)
        point = {x, y}

        if getIsPointInBox(point, @initialShapeBoundingRect)
          @isDragging = true

          @dragOffset = {
            x: x - @initialShapeBoundingRect.x,
            y: y - @initialShapeBoundingRect.y
          }

        lc.setShapesInProgress([@_getSelectionShape(lc.ctx), @currentShape])
        lc.repaintLayer('main')

      else
        @_clearCurrentShape(lc)

    onMove = ({x, y}) =>
      if @currentShape && @isDragging
        # This will probably work better if each shape has its own move method
        @didDrag = true

        newX = x - @dragOffset.x
        newY = y - @dragOffset.y

        boundingRect = @currentShape.getBoundingRect(lc.ctx)
        xDiff = boundingRect.x - newX
        yDiff = boundingRect.y - newY

        if @currentShape.x?
          @currentShape.x = newX
          @currentShape.y = newY

        if @currentShape.x1?
          @currentShape.x1 = @currentShape.x1 - xDiff
          @currentShape.x2 = @currentShape.x2 - xDiff
          @currentShape.y1 = @currentShape.y1 - yDiff
          @currentShape.y2 = @currentShape.y2 - yDiff

        if @currentShape.smoothedPoints?
          newSmoothedPoints = @currentShape.smoothedPoints.map((p) =>
            p.x = p.x - xDiff
            p.y = p.y - yDiff
            p
          )

          @currentShape.points = newSmoothedPoints
          @currentShape.smoothedPoints = newSmoothedPoints

        lc.setShapesInProgress([@_getSelectionShape(lc.ctx), @currentShape])
        lc.repaintLayer('main')

    onUp = ({x, y}) =>
      if @isDragging
        @isDragging = false
        lc.trigger('lc-shape-moved', shapeToJSON(@currentShape)) if @didDrag
        lc.repaintLayer('main')
        @_drawPickerCanvas lc, lc.shapes.map (shape, index) =>
          shape.createWithColor?("##{@_intToHex(index)}") || shape

    pickerUnsubscribeFuncs.push lc.on 'lc-pointerdown', onDown
    pickerUnsubscribeFuncs.push lc.on 'lc-pointerdrag', onMove
    pickerUnsubscribeFuncs.push lc.on 'lc-pointerup', onUp

  willBecomeInactive: (lc) ->
    @pickerUnsubscribe()
    @_cancel(lc)

  _cancel: (lc) ->
    @_clearCurrentShape(lc)

  _clearCurrentShape: (lc) ->
    @currentShape = null
    lc.setShapesInProgress([])
    lc.repaintLayer('main')

  _drawPickerCanvas: (lc, shapes) ->
    @picker.width = lc.canvas.width
    @picker.height = lc.canvas.height
    @pickerCtx.clearRect(0, 0, @picker.width, @picker.height)
    lc.draw(shapes, @pickerCtx)

  _intToHex: (i) ->
    "000000#{parseInt i, 16}".slice(-6)

  _getPixel: (x, y, lc, ctx) ->
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

  _getSelectionShape: (ctx, backgroundColor=null) ->
    createShape('SelectionBox', {shape: @currentShape, ctx, backgroundColor, drawHandles: false})
