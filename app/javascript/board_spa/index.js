import React from 'react'
import ReactDOM from 'react-dom'
import Board from './components/Board'
import jsonResponse from './fake_json'

document.addEventListener('DOMContentLoaded', () => {
    ReactDOM.render(
      <Board json={jsonResponse}/>,
      document.getElementById('board-spa'),
    )
  })
