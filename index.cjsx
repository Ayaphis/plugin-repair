{ROOT, React, ReactBootstrap, FontAwesome, resolveTime, notify, config} = window
{Grid, Col, Table, Label, Tabs, Tab, Input} = ReactBootstrap
{relative, join} = require 'path-extra'

delayTime = 10
firstAccount = 20 * 60 + delayTime
workShip = 19
repairItem = 86
initNotified = [false, false, false, false]
initStateFleets = [
    inRepair: false
    name: ''
    ships: []
    startTime: -1
    repairCondition: [0, 0, 0, 0, 0, 0]
    akashiCapacity: 0
  ,
    inRepair: false
    name: ''
    ships: []
    startTime: -1
    repairCondition: [0, 0, 0, 0, 0, 0]
    akashiCapacity: 0
  ,
    inRepair: false
    name: ''
    ships: []
    startTime: -1
    repairCondition: [0, 0, 0, 0, 0, 0]
    akashiCapacity: 0
  ,
    inRepair: false
    name: ''
    ships: []
    startTime: -1
    repairCondition: [0, 0, 0, 0, 0, 0]
    akashiCapacity: 0
]

initFleets = [
    span: 0
    efficiency: 0
    maxEfficiency: -1
    maxTime: -1
    spentNode: null
    efficiencyNode: null
    suggestionNode: null
  ,
    span: 0
    efficiency: 0
    maxEfficiency: -1
    maxTime: -1
    spentNode: null
    efficiencyNode: null
    suggestionNode: null
  ,
    span: 0
    efficiency: 0
    maxEfficiency: -1
    maxTime: -1
    spentNode: null
    efficiencyNode: null
    suggestionNode: null
  ,
    span: 0
    efficiency: 0
    maxEfficiency: -1
    maxTime: -1
    spentNode: null
    efficiencyNode: null
    suggestionNode: null
]

module.exports =
  name: 'Repair'
  displayName: <span><FontAwesome key={0} name='medkit' /> 泊地修理 </span>
  priority: 9
  author: 'Ayaphis'
  link: 'https://github.com/Ayaphis'
  description: '泊地修理'
  version: '制杖版'
  reactClass: React.createClass
    fleets: Object.clone initFleets
    getInitialState: ->
      notified: Object.clone initNotified
      fleets: Object.clone initStateFleets
      checkTime: config.get 'plugin.Repair.checkTime', 5
    compareFleet: (fleetA, fleetB) ->
      if fleetA? and fleetB? and fleetA.ships.length == fleetB.ships.length
        for ship ,idx in fleetA.ships
          if ship.id != fleetB.ships[idx].id or ship.hp != fleetB.ships[idx].hp
            return false
        return true
      return false
    isInRepair: (fleet) ->
      {_slotitems, _ships, $ships} = window
      if fleet[0] isnt -1 and $ships[_ships[fleet[0]].api_ship_id].api_stype is workShip and (_ships[fleet[0]].api_nowhp * 4 // _ships[fleet[0]].api_maxhp) > 2
        akashiCapacity = 1
        for itemId in _ships[fleet[0]].api_slot #TODO, correct name
          continue if itemId == -1
          if _slotitems[itemId].api_slotitem_id is repairItem
            akashiCapacity += 1
        console.log akashiCapacity
        for i in [0 .. akashiCapacity]
          if fleet[i] isnt -1
            if _ships[fleet[i]].api_nowhp isnt _ships[fleet[i]].api_maxhp
              if (_ships[fleet[i]].api_nowhp * 2 > _ships[fleet[i]].api_maxhp)  ##
                if not (fleet[i] in window._ndocks)
                  return true
      return false
    calculateRepairCondition: (fleet) ->
      {_slotitems, _ships, $ships} = window
      if fleet[0] isnt -1 and $ships[_ships[fleet[0]].api_ship_id].api_stype is workShip and (_ships[fleet[0]].api_nowhp * 4 // _ships[fleet[0]].api_maxhp) > 2
        akashiCapacity = 1
        for itemId in _ships[fleet[0]].api_slot #TODO, correct name
          continue if itemId == -1
          if _slotitems[itemId].api_slotitem_id is repairItem
            akashiCapacity += 1
      repairCondition = [0, 0, 0, 0, 0, 0]
      for i in [1 .. 5]
        if i <= akashiCapacity
          if fleet[i] isnt -1
            if _ships[fleet[i]].api_nowhp isnt _ships[fleet[i]].api_maxhp
              if (_ships[fleet[i]].api_nowhp * 2 > _ships[fleet[i]].api_maxhp)  ##
                if not (fleet[i] in window._ndocks)
                  repairCondition[i] = 1
      ret = 
        repairCondition: repairCondition
        akashiCapacity: akashiCapacity
    handleSetCheckTime: (e) ->
      config.set 'plugin.Repair.checkTime', @refs.checkTime.getValue()
      @setState
        checkTime: @refs.checkTime.getValue()
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
              repairCondition: [0, 0, 0, 0, 0, 0]
              akashiCapacity: 0
            if _inRepair
              for ship_id in deck.api_ship when ship_id isnt -1
                ship =
                  id: ship_id
                  hp: _ships[ship_id].api_nowhp
                  maxHp: _ships[ship_id].api_maxhp
                  repairTime: _ships[ship_id].api_ndock_time // 1000
                fleets[i].ships.push ship
              {repairCondition, akashiCapacity} = @calculateRepairCondition deck.api_ship
              fleets[i].repairCondition = repairCondition
              fleets[i].akashiCapacity = akashiCapacity
          # console.log  fleets
          # console.log @state.fleets
          for i in [0..3] when @state.fleets[i].inRepair
            if @compareFleet(fleets[i], @state.fleets[i])
              fleets[i].startTime = @state.fleets[i].startTime
              notified[i] = @state.notified[i]
          @setState
            fleets: fleets
            notified: notified
    calculateEfficency: (elapse, fleetIndex) ->
      elapse -= delayTime
      fleet = @state.fleets[fleetIndex]
      if fleet.inRepair
        if elapse < 20 * 60
          0
        else
          timeSum = 0
          for ship, idx in fleet.ships
            if ship.repairTime isnt 0 and fleet.repairCondition[idx] is 1
              timeSum += Math.min(ship.maxHp - ship.hp, Math.max(1, (ship.maxHp - ship.hp) * elapse // ship.repairTime)) * ship.repairTime / (ship.maxHp - ship.hp)
          (timeSum  * 1000 // (fleet.akashiCapacity * elapse)) / 10
      else
        0
    bindNode: ->
      for i in [0..3] when @state.fleets[i].inRepair
        @fleets[i].spentNode = document.querySelector("#repair-table-row#{i}-spent")
        @fleets[i].efficiencyNode = document.querySelector("#repair-table-row#{i}-efficiency")
        @fleets[i].suggestionNode = document.querySelector("#repair-table-row#{i}-suggestion")
    initFleetsArg: ->
      nowTime = (new Date).getTime()
      for i in [0..3] when @state.fleets[i].inRepair
        @fleets[i].span = (nowTime - @state.fleets[i].startTime) // 1000
        @fleets[i].efficiency = @calculateEfficency @fleets[i].span, i
        startTime = Math.max(firstAccount, @fleets[i].span)
        endTime = startTime + @state.checkTime * 60
        timeCheckList = [startTime]
        for ship in @state.fleets[i].ships when ship.maxHp isnt ship.hp
          step = Math.ceil(ship.repairTime / ( ship.maxHp - ship.hp))
          idx = 1
          while (step * idx + delayTime) < endTime
            if (step * idx + delayTime) > startTime
              timeCheckList.push step * idx + delayTime
            idx++
        @fleets[i].maxEfficiency = -1
        @fleets[i].maxTime = 0
        for elapsedTime in timeCheckList
          tmp = @calculateEfficency elapsedTime, i
          if tmp > @fleets[i].maxEfficiency
            @fleets[i].maxEfficiency = tmp
            @fleets[i].maxTime = elapsedTime
    componentDidMount: ->
      window.addEventListener 'game.response', @handleResponse
      setInterval @updateCount, 1000
      @bindNode()
      @initFleetsArg()
    componentWillUnmount: ->
      window.removeEventListener 'game.response', @handleResponse
      clearInterval @updateCount, 1000
    componentDidUpdate: ->
      @bindNode()
      @initFleetsArg()
    updateCount: ->
      nowTime = (new Date).getTime()
      {notified, fleets} = @state
      for fleet, i in fleets when fleet.inRepair
          @fleets[i].span = (nowTime - @state.fleets[i].startTime) // 1000
          if @fleets[i].span > @fleets[i].maxTime + delayTime
            @initFleetsArg()
          @fleets[i].spentNode?.innerHTML = resolveTime @fleets[i].span
          @fleets[i].efficiencyNode?.innerHTML = "#{@calculateEfficency @fleets[i].span, i}%"
          @fleets[i].suggestionNode?.innerHTML = resolveTime Math.max(0, @fleets[i].maxTime - @fleets[i].span)
          # console.log fleets
          if @fleets[i].span > firstAccount and !notified[i]
            window.notify "#{fleet.name} 第一次结算可能",
              type: 'repair'
              icon: join(ROOT, 'assets', 'img', 'operation', 'repair.png')
            notified[i] = true
            @setState
              fleets: fleets
              notified: notified
    render: ->
      <div>
        <Grid>
          <Col xs={12}>
            <Table>
              <thead>
                <tr>
                  <td>舰队名</td>
                  <td>已修理</td>
                  <td>修理效率</td>
                  <td>建议刷新</td>
                </tr>
              </thead>
              <tbody>
              {
                for i in [0..3]
                  <tr key={i}>
                    <td>{@state.fleets[i].name}</td>
                    <td>
                      {
                        if @state.fleets[i].inRepair
                          <Label bsStyle='primary' id={"repair-table-row#{i}-spent"}>{resolveTime @fleets[i].span}</Label>
                        else
                          <Label bsStyle='default'></Label>
                      }
                    </td>
                    <td>
                      {
                        if @state.fleets[i].inRepair
                          <Label bsStyle='primary' id={"repair-table-row#{i}-efficiency"}>{"#{@calculateEfficency @fleets[i].span, i}%"}</Label>
                        else
                          <Label bsStyle='default'></Label>
                      }
                    </td>
                    <td>
                      {
                        if @state.fleets[i].inRepair
                          <Label bsStyle='primary' id={"repair-table-row#{i}-suggestion"}>{resolveTime Math.max(0, @fleets[i].maxTime - @fleets[i].span)}</Label>
                        else
                          <Label bsStyle='default'></Label>
                      }
                    </td>
                  </tr>
              }
              </tbody>
            </Table>
          </Col>
          <Col xs={12}>
            <div>
              查找之后
              <div style={display: 'inline-block'}>
                <Input style={width: 55, paddingLeft: 5, textAlign: 'right'} type="number" ref="checkTime" value={@state.checkTime} onChange={@handleSetCheckTime}/>
              </div>
              min修理效率最高的时间点
            </div>
          </Col>
        </Grid>
      </div>
