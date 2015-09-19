{ROOT, React, ReactBootstrap, FontAwesome, resolveTime, notify} = window
{Table, Label} = ReactBootstrap
{relative, join} = require 'path-extra'

AkashiTime = delayTime = 30
firstAccount = 20 * 60 + delayTime + AkashiTime
workShip = 19
repairItem = 86
initNotified = [false, false, false, false]
initFleets = [
    inRepair: false
    name: ''
    ships: []
    startTime: -1
    span: -1
  ,
    inRepair: false
    name: ''
    ships: []
    startTime: -1
    span: -1
  ,
    inRepair: false
    name: ''
    ships: []
    startTime: -1
    span: -1
  ,
    inRepair: false
    name: ''
    ships: []
    startTime: -1
    span: -1
]

module.exports =
  name: 'Repair'
  displayName: <span><FontAwesome key={0} name='medkit' /> 泊地修理 </span>
  priority: 9
  author: 'Ayaphis'
  link: 'https://github.com/Ayaphis'
  description: '泊地修理'
  version: '1.2.9'
  reactClass: React.createClass
    getInitialState: ->
      notified: Object.clone initNotified
      fleets: Object.clone initFleets
    compareFleet: (fleetA, fleetB) ->
      if fleetA? and fleetB? and fleetA.ships.length == fleetB.ships.length
        for ship ,idx in fleetA.ships
          if ship.id != fleetB.ships[idx].id or ship.hp != fleetB.ships[idx].hp
            return false
        return true
      return false
    isInRepair: (fleet) ->
      {_slotitems, _ships, $ships} = window
      if fleet[0] isnt -1 
        if $ships[_ships[fleet[0]].api_ship_id].api_stype is workShip 
          if (_ships[fleet[0]].api_nowhp * 2 > _ships[fleet[0]].api_maxhp)
            akashiCapacity = 1
            for itemId in _ships[fleet[0]].api_slot #TODO, correct name
              continue if itemId == -1
              if _slotitems[itemId].api_slotitem_id is repairItem
                akashiCapacity += 1
            #console.log akashiCapacity
            for i in [0 .. akashiCapacity]
              if fleet[i] isnt -1
                if _ships[fleet[i]].api_nowhp isnt _ships[fleet[i]].api_maxhp
                  if (_ships[fleet[i]].api_nowhp * 2 > _ships[fleet[i]].api_maxhp)  ##
                    if not (fleet[i] in window._ndocks)
                      return true
      return false
    handleResponse: (e) ->
      {method, path, body, postBody} = e.detail
      {_ships, _decks} = window
      fleets = Object.clone initFleets
      notified = Object.clone initNotified
      switch path
        when '/kcsapi/api_port/port', '/kcsapi/api_req_hensei/change'
          nowTime = (new Date).getTime()
          for deck, i in _decks
            _inRepair = @isInRepair deck.api_ship
            fleets[i] =
              inRepair:  _inRepair
              name: deck.api_name
              ships: []
              startTime: nowTime
              span: -1
            if _inRepair
              for ship_id in deck.api_ship when ship_id isnt -1
                ship =
                  id: ship_id
                  hp: _ships[ship_id].api_nowhp
                fleets[i].ships.push ship
          # console.log  fleets
          # console.log @state.fleets
          for i in [0..3] when @state.fleets[i].inRepair
            if @compareFleet(fleets[i], @state.fleets[i])
              fleets[i].startTime = @state.fleets[i].startTime
              fleets[i].span = (nowTime - @state.fleets[i].startTime) // 1000
              notified[i] = @state.notified[i]
          @setState
            fleets: fleets
            notified: notified
    componentDidMount: ->
      window.addEventListener 'game.response', @handleResponse
      setInterval @updateCount, 1000
    componentWillUnmount: ->
      window.removeEventListener 'game.response', @handleResponse
      clearInterval @updateCount, 1000
    updateCount: ->
      {notified, fleets} = @state
      nowTime = (new Date).getTime()
      for fleet, i in fleets when fleet.inRepair
          fleet.span = (nowTime - fleet.startTime) // 1000
          # console.log fleets
          if fleet.span > firstAccount and !notified[i]
            window.notify "#{fleet.name} 第一次结算可能",
              type: 'repair'
              icon: join(ROOT, 'assets', 'img', 'operation', 'repair.png')
            notified[i] = true
      @setState
        fleets: fleets
        notified: notified
    render: ->
      <div>
        <Table>
          <tbody>
          {
            for i in [0..3]
              <tr key={i}>
                <td>{@state.fleets[i].name}</td>
                <td>
                  {
                    if @state.fleets[i].inRepair
                      <Label bsStyle='primary'>{resolveTime @state.fleets[i].span}</Label>
                    else
                      <Label bsStyle='default'></Label>
                  }
                </td>
              </tr>
          }
          </tbody>
        </Table>
      </div>
