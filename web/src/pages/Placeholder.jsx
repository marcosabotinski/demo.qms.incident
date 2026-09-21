export default function Placeholder({ title, note }) {
  return (
    <div>
      <div className="page-head">
        <div>
          <h2>{title}</h2>
          <p>{note}</p>
        </div>
      </div>
      <div className="card empty">This module is out of scope for the live demo. Use Incidents to create and open records.</div>
    </div>
  );
}
