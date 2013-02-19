# yam.js
#
# Easy jQuery Responsive Drop-Down-Menu.
#
# Source: https://github.com/2robots/yam.js
# Authors: Franz Wilding
# Licence: GPL v3

(($, window) ->

  pluginName = 'yam'
  document = window.document

  defaults =
    hover_delay: 1000
    remember_menu_state: false
    hover_animations: {
      in: 100
      out: 100
    }
    layout_vertical_at: 3
    selectors: [
      ['self', '> li']
      ['> ul, > ol', '> li']
    ]
    callbacks:
      mouseenter: undefined
      mouseleave: undefined
      click: undefined
    click_events: 'click, touchend'

    is_active: (element)->
      return element.hasClass 'active'

  # The actual plugin constructor
  class YamWrapper


    # wrapper constructor
    constructor: (@element, options) ->
      @options = {}
      @menus = []
      @active = []
      @options = $.extend {}, defaults, options
      @init()

    # init the wrapper
    init: ->
      that = @
      $(@element).addClass 'yam-menu'

      # init all Layouts
      @initLayouts()

    initLayouts: ->

      that = @

      # init the menu
      @_walkMenu $(@element), (that, parent, items, level, old_parent)->

        # add layout-class to parent
        parent.addClass 'yam-' + that._getLayout(level)
        parent.data 'yam-level', level

        if that.menus[level] == undefined
          that.menus[level] = []

        that.menus[level].push parent

        if that._getLayout(level) == 'horizontal'
          if that.options.is_active(old_parent)
            that.active[level] = parent
            old_parent.addClass 'yam-active'

        items.each (i, item)->
          $(item).addClass 'yam-item'

          if that.options.is_active($(item))
            $(item).addClass 'yam-active'

          that.manageClick $(item)

          if that._getLayout(level) == 'vertical'
            $(item).css 'min-width', that._getElementWidth($(item))

        if parent != old_parent
          that.manageHover old_parent, parent

          if items.length > 0
            old_parent.addClass 'yam-parent'


      # this holds all horizontal menues heights, so we can calculate margin-bottom
      total_menu_height = parseInt($(@element).css('margin-bottom'), 10)
      $(@element).data 'yam-margin-bottom', total_menu_height

      #hide all menues, that shouldn't be visible on start
      $.each @menus, (l, level)->

        level_height = 0

        $.each level, (i, e)->
          ignore = false
          if that.active[l] != undefined
            if that.active[l] == e
              ignore = true

          if e[0] == that.element
            ignore = true

          if !ignore
            $(e).hide()

          # get the menu height
          if e[0] != that.element && e.hasClass 'yam-horizontal'
            menu_height = that._getElementHeight(e)
            if menu_height > level_height
              level_height = menu_height

        total_menu_height = total_menu_height + level_height

      # set the margin-bottom to the menu
      $(@element).css 'margin-bottom', total_menu_height

      # manage all visible menues
      $.each @active, (l, menu)->
        if menu != undefined
          that.checkHeightForMenu menu

      # when resizing the window, we need to manage all active menues heights
      $(window).resize $.debounce(50, ->

        # manage all active menues
        $.each that.active, (l, menu)->
          if menu != undefined
            that.checkHeightForMenu menu

        # manage menu margin
        total_menu_height = $(that.element).data 'yam-margin-bottom'

        $.each that.menus, (l, level)->
          level_height = 0
          $.each level, (i, e)->
            # get the menu height
            if e[0] != that.element && e.hasClass 'yam-horizontal'
              menu_height = that._getElementHeight(e)
              if menu_height > level_height
                level_height = menu_height

          total_menu_height = total_menu_height + level_height

        # set the margin-bottom to the menu
        $(that.element).css 'margin-bottom', total_menu_height
      )

    checkHeightForMenu: (element)->
      level = element.data('yam-level')

      if level != null
        if @menus[level-1][0] != undefined
          height = @_getElementHeight @menus[level-1][0]

          if (@_getLayout(level) == 'horizontal')
            element.css 'top', height

    # position vertical-menu next to parent menu
    # first we try to add ourself right to the menu, then left
    positionSubmenu: (element, old_parent)->

      level = element.data('yam-level')
      if @_getLayout(level) == 'vertical'

          menu_width = @_getElementWidth element, true
          body_width = @_getElementWidth $("body")

          element.css 'top', 'auto'
          element.css 'bottom', 'auto'
          element.css 'left', 'auto'
          element.css 'right', 'auto'

          if @_getLayout(level-1) == 'vertical'
            parent_width = @_getElementWidth old_parent, true

            # put the menu right to parent menu
            if body_width > ( parent_width + menu_width + old_parent.offset().left)
              element.css 'right', -menu_width
              element.css 'top', old_parent.position().top

            # put the menu left to parent menu
            else if menu_width < old_parent.offset().left
              element.css 'left', -menu_width
              element.css 'top', old_parent.position().top

            # if there isn't space left and right, we need to position the submenu below
            else
              element.css 'bottom', - @_getElementHeight element, true

          else
            # if the parent is horizontal OR vertical, we don't have to do that much
            # just check, if there is enough space right to the item
            if body_width < (menu_width + old_parent.offset().left)
              element.css 'left', 'auto'
              element.css 'right', 0

    # manage click
    manageClick: (element)->

      that = @

      if Modernizr.touch
        element.bind @options.click_events, (event)->

          #if !element.hasClass 'yam-active'
          event.preventDefault()

          data = {
            obj: that
            element: element
          }

          # open menu
          that._manageMouseEnter element, element.find('.yam-horizontal, .yam-vertical').first()

          # add active class
          element.addClass "yam-active"


          # hide menu on window.click
          $(window).bind that.options.click_events, data, that.windowClickHandler


      # call callback
      if $.isFunction @options.callbacks.click
        element.bind that.options.click_events, @options.callbacks.click

    #windowClickHandler
    windowClickHandler: (event)->
      if $(event.data.element).closest('.yam-menu')[0] != $(event.target).closest('.yam-menu')[0]
        that = @
        setTimeout (->
          $(event.data.element).removeClass "yam-active"
          event.data.obj._manageMouseLeave $(event.data.element), $(event.data.obj.element)
          $(event.data.obj.element).find('.yam-active').removeClass 'yam-active'
          $(window).unbind event.data.obj.options.click_events, that.windowClickHandler
        ), 0


    # manage hover
    manageHover: (element, child)->
      that = @

      # do not use hover action on active menues, but make sure it is visible
      if $.inArray(child, @active) > 0
        element.mouseenter (event)->
          element.siblings().find('.yam-hover').each (i, e)->
            that._hideMenu $(e)
          child.show()
        return



      element.mouseenter (event)->

        # stop any posible mouse-leave-timers on this...
        clearTimeout element.data 'yam-mouseleave-timer'
        that._manageMouseEnter element, child

      element.mouseleave (event)->

        # leave after a short periode
        timer = setTimeout (->
          that._manageMouseLeave element, child
        ), that.options.hover_delay

        element.data 'yam-mouseleave-timer', timer

    # manageMouseEnter
    _manageMouseEnter: (element, child)->
      if !@isMenuHover(child)

        that = @

        # ...and hide all siblings
        element.siblings().find('.yam-hover').each (i, e)->
            that._hideMenu $(e)

        # and all active menues from this level
        if @active[child.data('yam-level')] != undefined
          @active[child.data('yam-level')].hide()

        # show this element
        @_showMenu child, element

        # callback
        if $.isFunction @options.callbacks.mouseenter
          @options.callbacks.mouseenter event, element


    # manageMenuLeave
    _manageMouseLeave: (element, child)->

      that = @
      child.find('.yam-horizontal, .yam-vertical').each (i, e)->
        that._hideMenu $(e)

      if (!@options.remember_menu_state) || (child.hasClass 'yam-vertical') || (@active[child.data('yam-level')] != undefined)
        @_hideMenu child

        # redisplay active menues
        if @active[child.data('yam-level')] != undefined
          @active[child.data('yam-level')].show()

      # callback
      if $.isFunction @options.callbacks.mouseleave
        @options.callbacks.mouseleave event, element

    #show menu
    _showMenu: (menu, parent)->
      if !@isMenuHover(menu)
        @checkHeightForMenu menu, parent
        @positionSubmenu menu, parent

        if menu.hasClass 'yam-horizontal'
          menu.fadeIn @options.hover_animations.in
        else
          menu.slideDown @options.hover_animations.in

        others = parent.siblings('.yam-active')
        others.addClass 'yam-inactive'
        others.removeClass 'yam-active'

        parent.addClass 'yam-active'
        menu.addClass 'yam-hover'

        @active[@options.layout_vertical_at + menu.data("yam-level")] = menu

    _hideMenu: (menu)->
      if @isMenuHover(menu)

        @active[@options.layout_vertical_at + menu.data("yam-level")] = undefined

        if menu.hasClass 'yam-horizontal'
          menu.fadeOut @options.hover_animations.out
        else
          menu.slideUp @options.hover_animations.out

        others = menu.closest('.yam-active').siblings('.yam-inactive')
        others.addClass 'yam-active'
        others.removeClass 'yam-inactive'

        menu.closest('.yam-active').removeClass 'yam-active'
        menu.removeClass 'yam-hover'

    isMenuHover: (menu)->
      menu.hasClass 'yam-hover'

    #recursively walk the menu, and call the function for each step
    _walkMenu: (parent, cal_function, level = 0, old_parent)->

      that = @
      p_sel = @_getSelector(level)[0]
      i_sel = @_getSelector(level)[1]

      if p_sel == 'self'
        $parent = parent
      else
        $parent = parent.find p_sel

      if($parent == undefined || $parent.length == 0)
        return;

      $items = $parent.find i_sel

      if($items == undefined || $items.length == 0)
        return;

      cal_function @, $parent, $items, level, parent

      $items.each (i, item)->
        that._walkMenu $(item), cal_function, level+1, old_parent


    _getSelector: (level)->
      if(level >= @options.selectors.length)
        @options.selectors[@options.selectors.length-1]
      else
        @options.selectors[level]

    _getLayout: (level)->
      if(level >= (@options.layout_vertical_at - 1))
        'vertical'
      else
        'horizontal'

    _getElementWidth: (element, out = false)->
      if !out
        element.outerWidth()
      else
        element.outerWidth() + parseInt(element.css("margin-left"), 10) + parseInt(element.css("margin-right"), 10)

    _getElementHeight: (element, out = false)->
      if !out
        element.outerHeight()
      else
        element.outerHeight() + parseInt(element.css("margin-top"), 10) + parseInt(element.css("margin-bottom"), 10)


  # A really lightweight plugin wrapper around the constructor,
  # preventing against multiple instantiations
  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(this, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new YamWrapper(@, options))
)(jQuery, window)



