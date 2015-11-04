Pencil = require './Pencil'
{createShape} = require '../core/shapes'


module.exports = class Eraser extends Pencil

  name: 'Eraser'
  iconName: 'eraser'

  makePoint: (x, y, lc) ->
    createShape('Point', {x, y, size: @strokeWidth, color: '#000'})
  makeShape: -> createShape('ErasedLinePath')
