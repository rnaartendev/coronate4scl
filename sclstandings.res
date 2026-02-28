open! Belt
open Data

@react.component
let make = (~players) => {
  <div className="content-area">
    <h2>{React.string("SCL Standings")}</h2>
    <table className="pagescores__table">
      <thead>
        <tr>
          <th>{React.string("Player")}</th>
          <th>{React.string("Rating")}</th>
          <th>{React.string("Games Played")}</th>
          <th>{React.string("Games Missed")}</th>
          <th>{React.string("Deduction")}</th>
          <th>{React.string("Adjusted Rating")}</th>
        </tr>
      </thead>
      <tbody>
        {players
        ->Array.map(player =>
          <tr key={player.name}>
            <td>{React.string(player.name)}</td>
            <td>{React.string(string_of_int(player.rating))}</td>
            <td>{React.string(string_of_int(player.games_played))}</td>
            <td>{React.string(string_of_int(player.games_missed))}</td>
            <td>{React.string(string_of_int(player.deduction))}</td>
            <td>{React.string(string_of_int(player.adjusted_rating))}</td>
          </tr>
        )
        ->React.array}
      </tbody>
    </table>
  </div>
}
