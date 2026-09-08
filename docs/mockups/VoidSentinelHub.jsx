import { useState, useEffect, useRef } from "react";

const C = {
  bg: "#08080f", surface: "#0d0d1e", border: "#1a1a30",
  cian: "#00e5ff", gold: "#f5a623", orange: "#ff6b00",
  purple: "#7b2fff", plat: "#7ec8e3", green: "#4aaa4a",
  red: "#e05050", blue: "#4a9eff", inactive: "#2a2a40",
  text: "#cccccc", dim: "#444444", dimmer: "#2a2a2a",
};

const fmt = (n) => n >= 1e6 ? (n/1e6).toFixed(1)+"M" : n >= 1000 ? (n/1000).toFixed(1)+"k" : String(n);

const cardStyle = (bg=C.surface, border=C.border, r=10) => ({
  background: bg, border: `1px solid ${border}`,
  borderRadius: r, padding: "10px 12px",
  display: "flex", alignItems: "center", gap: 10,
});

const btnStyle = (color, afford) => ({
  background: afford ? color+"22" : "#111",
  border: `1px solid ${afford ? color : C.border}`,
  borderRadius: 8, padding: "5px 10px", cursor: afford ? "pointer" : "default",
  textAlign: "center", minWidth: 68,
});

// ── NEXUS DATA ────────────────────────────────────────────────────────────
const NEXUS = {
  ataque: { color: C.red, mejoras: [
    {id:"danio",nombre:"Daño base",nivel:12,coste:1840,desc:"+2.5% daño por nivel"},
    {id:"vel",nombre:"Velocidad de ataque",nivel:8,coste:2100,desc:"+1 disparo/seg"},
    {id:"crit",nombre:"Disparo crítico",nivel:5,coste:3200,desc:"+5% prob. crítico"},
    {id:"multi",nombre:"Multidisparo",nivel:3,coste:5800,desc:"+1 proyectil adicional"},
    {id:"rebote",nombre:"Rebote",nivel:2,coste:8400,desc:"+1 rebote por proyectil"},
    {id:"alcance",nombre:"Alcance de rebote",nivel:1,coste:9200,desc:"+20% distancia rebote"},
  ]},
  defensa: { color: C.blue, mejoras: [
    {id:"salud",nombre:"Salud máxima",nivel:15,coste:1600,desc:"+500 HP por nivel"},
    {id:"recup",nombre:"Recuperación",nivel:7,coste:2400,desc:"+0.5% regen/seg"},
    {id:"esc",nombre:"Escudo",nivel:4,coste:4200,desc:"+10% absorción"},
    {id:"dur",nombre:"Dureza de escudo",nivel:3,coste:5600,desc:"-5% daño con escudo"},
    {id:"pulso",nombre:"Pulso Quartz",nivel:2,coste:7800,desc:"+15% daño del pulso"},
    {id:"poder",nombre:"Poder del pulso",nivel:1,coste:10200,desc:"+25% radio pulso"},
  ]},
  bonus: { color: C.purple, mejoras: [
    {id:"e_asc",nombre:"Energía por ascensión",nivel:10,coste:2200,desc:"+5% monedas al subir"},
    {id:"e_esp",nombre:"Energía por espectro",nivel:8,coste:2600,desc:"+3% drop por enemigo"},
    {id:"ec_asc",nombre:"Ecos de ascensión",nivel:6,coste:3400,desc:"+2% fragmentos"},
    {id:"ec_rap",nombre:"Ecos rápidos",nivel:4,coste:4800,desc:"-10% tiempo entre drops"},
    {id:"mg1",nombre:"Mejora gratuita I",nivel:2,coste:12000,desc:"1 mejora gratis/10 asc."},
    {id:"mg2",nombre:"Mejora gratuita II",nivel:1,coste:18000,desc:"2 mejoras gratis/15 asc."},
    {id:"int",nombre:"Tasa de interés",nivel:0,coste:6000,desc:"+2.5% interés"},
  ]},
  commander: { color: C.orange, mejoras: [
    {id:"blind",nombre:"Blindaje Commander",nivel:5,coste:4400,desc:"-8% daño del Cmd."},
    {id:"prec",nombre:"Precisión Commander",nivel:3,coste:7200,desc:"+10% crítico al Cmd."},
    {id:"aura",nombre:"Aura Commander",nivel:2,coste:9800,desc:"-5% vel. spawn Cmd."},
    {id:"cad",nombre:"Cadencia Commander",nivel:1,coste:14000,desc:"+15% daño zona Cmd."},
  ]},
};

// ── FORJA DATA ────────────────────────────────────────────────────────────
const FORJA_INIT = {
  ofensiva: [
    {id:"enjambre",nombre:"Enjambre de Proyectiles",desc:"24 proyectiles en 360°",coste:80,umbral:2100,req:[],
     params:[{id:"p_cant",nombre:"Proyectiles",nivel:0,desc:"+4 proyectiles",base:20},{id:"p_dan",nombre:"Daño",nivel:0,desc:"+10% daño",base:20},{id:"p_vel",nombre:"Velocidad",nivel:0,desc:"+50 px/s",base:20},{id:"p_cd",nombre:"Cooldown",nivel:0,desc:"-1s",base:35},{id:"p_pen",nombre:"Penetración",nivel:0,desc:"+1 enemigo",base:55}]},
    {id:"emp",nombre:"Pulso EMP",desc:"Anti-escudo y anti-armadura",coste:120,umbral:2500,req:["enjambre"],
     params:[{id:"e_dan",nombre:"Daño base",nivel:0,desc:"+20% daño",base:35},{id:"e_mul",nombre:"Multiplicador",nivel:0,desc:"+0.3x vs escudo",base:55},{id:"e_stu",nombre:"Duración stun",nivel:0,desc:"+1s",base:35},{id:"e_cd",nombre:"Cooldown",nivel:0,desc:"-1.5s",base:55}]},
    {id:"cadena",nombre:"Detonación en Cadena",desc:"Explosión en cascada",coste:180,umbral:3500,req:["enjambre","emp","escudoc","tiempo"],
     params:[{id:"c_dan",nombre:"Daño explosión",nivel:0,desc:"+30% daño",base:55},{id:"c_rad",nombre:"Radio",nivel:0,desc:"+15px",base:55},{id:"c_sal",nombre:"Saltos",nivel:0,desc:"+1 salto",base:80},{id:"c_cd",nombre:"Cooldown",nivel:0,desc:"-2s",base:80}]},
    {id:"singularidad",nombre:"Singularidad",desc:"Agujero negro temporal",coste:280,umbral:5000,req:["enjambre","emp","cadena","escudoc","tiempo","emergencia"],
     params:[{id:"s_fue",nombre:"Fuerza",nivel:0,desc:"+2 unidades/s²",base:80},{id:"s_dan",nombre:"Daño",nivel:0,desc:"+25%",base:80},{id:"s_dur",nombre:"Duración",nivel:0,desc:"+0.5s",base:80},{id:"s_cd",nombre:"Cooldown",nivel:0,desc:"-2s",base:120}]},
  ],
  defensiva: [
    {id:"escudoc",nombre:"Escudo de Colapso",desc:"Barrera de absorción",coste:80,umbral:2100,req:[],
     params:[{id:"ec_abs",nombre:"Absorción",nivel:0,desc:"+50% vida máx.",base:20},{id:"ec_dur",nombre:"Duración",nivel:0,desc:"+1s",base:35},{id:"ec_cd",nombre:"Cooldown",nivel:0,desc:"-2s",base:35},{id:"ec_reb",nombre:"Rebote",nivel:0,desc:"Daño al romperse",base:80}]},
    {id:"tiempo",nombre:"Campo de Tiempo",desc:"Ralentiza enemigos",coste:120,umbral:2500,req:["escudoc"],
     params:[{id:"t_slo",nombre:"Intensidad slow",nivel:0,desc:"-5% vel.",base:35},{id:"t_dur",nombre:"Duración",nivel:0,desc:"+1s",base:35},{id:"t_cd",nombre:"Cooldown",nivel:0,desc:"-2s",base:55},{id:"t_dan",nombre:"Daño en slow",nivel:0,desc:"+15%",base:80}]},
    {id:"emergencia",nombre:"Protocolo de Emergencia",desc:"Curación instantánea",coste:180,umbral:3500,req:["escudoc","tiempo","enjambre","emp"],
     params:[{id:"em_cur",nombre:"% Curación",nivel:0,desc:"+5%",base:55},{id:"em_cd",nombre:"Cooldown",nivel:0,desc:"-2s",base:55},{id:"em_reg",nombre:"Regen",nivel:0,desc:"+1% regen/s",base:80}]},
    {id:"interferencia",nombre:"Manto de Interferencia",desc:"Bloquea targeting",coste:280,umbral:5000,req:["escudoc","tiempo","emergencia","enjambre","emp","cadena"],
     params:[{id:"i_dur",nombre:"Duración",nivel:0,desc:"+1s",base:80},{id:"i_cd",nombre:"Cooldown",nivel:0,desc:"-2s",base:80},{id:"i_ref",nombre:"Reflejo",nivel:0,desc:"Proyectiles al enemigo",base:180}]},
  ],
};

const LOGROS = [
  {nombre:"Primera sangre",desc:"Completa tu primera partida",ok:true},
  {nombre:"Commander Slayer",desc:"Elimina tu primer Commander",ok:true},
  {nombre:"Superviviente",desc:"Alcanza la ascensión 500",ok:true},
  {nombre:"Forjador",desc:"Desbloquea la Forja",ok:false},
  {nombre:"Tier II",desc:"Supera la ascensión 5.000",ok:false},
  {nombre:"Intocable",desc:"Llega a asc. 200 sin daño",ok:false},
  {nombre:"Void Master",desc:"Alcanza la ascensión 10.000",ok:false},
];

const PACKS = [
  {cantidad:50,precio:"0,99€",bonus:"",highlight:false},
  {cantidad:150,precio:"2,49€",bonus:"+20 extra",highlight:false},
  {cantidad:400,precio:"5,99€",bonus:"+80 extra",highlight:true},
  {cantidad:1000,precio:"13,99€",bonus:"+250 extra",highlight:false},
];

// ── CORE ANIMATION ────────────────────────────────────────────────────────
function NexusCore() {
  const [scale, setScale] = useState(1);
  useEffect(() => {
    let t = 0, dir = 1;
    const id = setInterval(() => {
      t += dir * 0.004;
      if (t >= 1) { t = 1; dir = -1; }
      else if (t <= 0) { t = 0; dir = 1; }
      setScale(1 + t * 0.08);
    }, 16);
    return () => clearInterval(id);
  }, []);
  return (
    <div style={{position:"relative",width:150,height:150,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
      {[140,112,84].map((s,i) => (
        <div key={i} style={{position:"absolute",width:s,height:s,borderRadius:"50%",border:`1px solid ${C.cian}${["15","22","33"][i]}`}} />
      ))}
      <div style={{position:"absolute",width:56,height:56,borderRadius:"50%",background:"#0a2a5e",border:`2px solid ${C.cian}`,display:"flex",alignItems:"center",justifyContent:"center",transform:`scale(${1+((scale-1)*0.5)})`}}>
        <div style={{width:26,height:26,borderRadius:"50%",background:C.cian,opacity:0.85,transform:`scale(${scale})`}} />
      </div>
    </div>
  );
}

// ── HOME ──────────────────────────────────────────────────────────────────
function HomeScreen({ gold, frags, plat }) {
  return (
    <div style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",padding:"0 16px",gap:14}}>
      <NexusCore />
      <div style={{display:"flex",alignItems:"center",gap:8,background:"#0e0e1e",border:`1px solid #1e1e3a`,borderRadius:20,padding:"5px 14px"}}>
        <span style={{color:C.dim,fontSize:9,letterSpacing:1}}>TIER</span>
        <div style={{display:"flex",gap:3}}>
          {[true,false,false].map((a,i) => <div key={i} style={{width:7,height:7,borderRadius:"50%",background:a?C.cian:"#1a1a2e"}} />)}
        </div>
        <span style={{color:C.cian,fontSize:10,fontWeight:500}}>I — Void Initiate</span>
      </div>
      <div style={{display:"flex",gap:8,width:"100%"}}>
        {[["ASCENSIÓN MÁX","1.847",C.cian],["PARTIDAS","312",C.text],["COMMANDERS","36",C.gold]].map(([k,v,c]) => (
          <div key={k} style={{flex:1,...cardStyle(),justifyContent:"center",flexDirection:"column",textAlign:"center"}}>
            <div style={{color:C.dim,fontSize:8,letterSpacing:0.5}}>{k}</div>
            <div style={{color:c,fontSize:15,fontWeight:500,marginTop:3}}>{v}</div>
          </div>
        ))}
      </div>
      <div style={{width:"100%",background:"#0a2a5e",border:`1px solid #1a6aff`,borderRadius:14,padding:14,textAlign:"center",cursor:"pointer"}}>
        <div style={{color:"#fff",fontSize:17,fontWeight:500,letterSpacing:3}}>JUGAR</div>
        <div style={{color:"#5599ff",fontSize:9,letterSpacing:1.5,marginTop:3}}>CONTINUAR ASCENSIÓN</div>
      </div>
    </div>
  );
}

// ── NEXUS ─────────────────────────────────────────────────────────────────
function NexusScreen({ gold, setGold }) {
  const [cat, setCat] = useState("ataque");
  const [levels, setLevels] = useState(() => {
    const l = {};
    Object.values(NEXUS).forEach(c => c.mejoras.forEach(m => { l[m.id] = m.nivel; }));
    return l;
  });
  const data = NEXUS[cat];
  const nCost = (m) => Math.round(m.coste * Math.pow(1.09, levels[m.id]));
  const buy = (m) => {
    const c = nCost(m);
    if (gold < c) return;
    setGold(g => g - c);
    setLevels(l => ({...l, [m.id]: l[m.id]+1}));
  };
  const tabs = [{k:"ataque",label:"⚔ Ataque",c:C.red},{k:"defensa",label:"🛡 Defensa",c:C.blue},{k:"bonus",label:"✦ Bonific.",c:C.purple},{k:"commander",label:"♛ Cmd.",c:C.orange}];
  return (
    <div style={{flex:1,display:"flex",flexDirection:"column",overflow:"hidden"}}>
      <div style={{flex:1,overflowY:"auto",padding:"8px 12px",display:"flex",flexDirection:"column",gap:7}}>
        {data.mejoras.map(m => {
          const cost = nCost(m); const afford = gold >= cost;
          return (
            <div key={m.id} style={cardStyle()}>
              <div style={{flex:1,minWidth:0}}>
                <div style={{color:C.text,fontSize:12,fontWeight:500,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{m.nombre}</div>
                <div style={{color:C.dim,fontSize:9,marginTop:2}}>{m.desc}</div>
                <div style={{display:"flex",alignItems:"center",gap:4,marginTop:5}}>
                  <span style={{color:"#555",fontSize:9}}>Nv.</span>
                  <span style={{color:data.color,fontSize:11,fontWeight:500}}>{levels[m.id]}</span>
                  <div style={{width:60,height:3,background:"#111",borderRadius:2,overflow:"hidden"}}>
                    <div style={{width:`${Math.min(levels[m.id]*5,100)}%`,height:"100%",background:data.color}} />
                  </div>
                </div>
              </div>
              <div style={{display:"flex",flexDirection:"column",alignItems:"center",gap:4,minWidth:68}}>
                <div style={btnStyle(data.color, afford)} onClick={() => buy(m)}>
                  <div style={{color:afford?data.color:C.dimmer,fontSize:10,fontWeight:500}}>MEJORAR</div>
                </div>
                <div style={{display:"flex",alignItems:"center",gap:2}}>
                  <span style={{color:afford?C.gold:C.dimmer,fontSize:9,fontWeight:700}}>©</span>
                  <span style={{color:afford?"#aaa":C.dimmer,fontSize:9}}>{fmt(cost)}</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
      <div style={{display:"flex",padding:"0 10px",gap:4,background:"#0b0b18",borderTop:`1px solid #141428`}}>
        {tabs.map(t => (
          <div key={t.k} onClick={() => setCat(t.k)}
            style={{flex:1,textAlign:"center",padding:"10px 2px 8px",fontSize:10,fontWeight:500,cursor:"pointer",
              color:cat===t.k?t.c:C.inactive, borderTop:`2px solid ${cat===t.k?t.c:"transparent"}`}}>
            {t.label}
          </div>
        ))}
      </div>
    </div>
  );
}

// ── FORJA ─────────────────────────────────────────────────────────────────
function ForjaScreen({ frags, setFrags }) {
  const [side, setSide] = useState("ofensiva");
  const [detalle, setDetalle] = useState(null);
  const [purchased, setPurchased] = useState({});
  const [params, setParams] = useState(() => {
    const p = {};
    [...FORJA_INIT.ofensiva, ...FORJA_INIT.defensiva].forEach(h =>
      h.params.forEach(pp => { p[pp.id] = 0; })
    );
    return p;
  });
  const asc = 2847;
  const allH = [...FORJA_INIT.ofensiva, ...FORJA_INIT.defensiva];
  const getState = (h) => {
    if (purchased[h.id]) return "comprada";
    if (!h.req.every(r => purchased[r])) return "bloqueada_req";
    if (asc < h.umbral) return "bloqueada_asc";
    if (frags < h.coste) return "sin_fondos";
    return "disponible";
  };
  const pCost = (p) => Math.round(p.base * Math.pow(1.09, params[p.id]));
  const color = side === "ofensiva" ? C.red : C.blue;
  const detalleH = detalle ? allH.find(h => h.id === detalle) : null;

  if (detalleH) {
    return (
      <div style={{flex:1,display:"flex",flexDirection:"column",overflow:"hidden"}}>
        <div style={{overflowY:"auto",flex:1,padding:"8px 12px",display:"flex",flexDirection:"column",gap:7}}>
          <div style={{color:C.dim,fontSize:9,letterSpacing:0.5,marginBottom:4}}>MEJORAS DE HABILIDAD</div>
          {detalleH.params.map(p => {
            const cost = pCost(p); const afford = frags >= cost; const maxed = params[p.id] >= 4;
            return (
              <div key={p.id} style={cardStyle()}>
                <div style={{flex:1}}>
                  <div style={{color:C.text,fontSize:12,fontWeight:500}}>{p.nombre}</div>
                  <div style={{color:C.dim,fontSize:9,marginTop:2}}>{p.desc}</div>
                  <div style={{display:"flex",alignItems:"center",gap:4,marginTop:5}}>
                    <span style={{color:"#555",fontSize:9}}>Nv.</span>
                    <span style={{color:color,fontSize:11,fontWeight:500}}>{params[p.id]}</span>
                    <div style={{width:60,height:3,background:"#111",borderRadius:2,overflow:"hidden"}}>
                      <div style={{width:`${params[p.id]*25}%`,height:"100%",background:color}} />
                    </div>
                    <span style={{color:"#2a2a3a",fontSize:9}}>/ 4</span>
                  </div>
                </div>
                <div style={{display:"flex",flexDirection:"column",alignItems:"center",gap:4,minWidth:68}}>
                  {maxed ? (
                    <div style={{background:"#0d1a0d",border:`1px solid #1a3a1a`,borderRadius:8,padding:"5px 8px",width:"100%",textAlign:"center"}}>
                      <span style={{color:"#1e5a1e",fontSize:9,fontWeight:500}}>MAX</span>
                    </div>
                  ) : (
                    <>
                      <div style={btnStyle(color, afford)} onClick={() => { if(!afford) return; setFrags(f=>f-cost); setParams(pp=>({...pp,[p.id]:pp[p.id]+1})); }}>
                        <div style={{color:afford?color:C.dimmer,fontSize:9,fontWeight:500}}>MEJORAR</div>
                      </div>
                      <div style={{display:"flex",alignItems:"center",gap:2}}>
                        <span style={{color:afford?C.orange:"#3a2a1a",fontSize:9}}>⬡</span>
                        <span style={{color:afford?"#aaa":"#3a2a1a",fontSize:9}}>{fmt(cost)}</span>
                      </div>
                    </>
                  )}
                </div>
              </div>
            );
          })}
        </div>
        <div style={{padding:"0 10px",background:"#0b0b18",borderTop:`1px solid #141428`}}>
          <div onClick={() => setDetalle(null)} style={{padding:"10px 0",color:C.orange,fontSize:11,cursor:"pointer",display:"flex",alignItems:"center",gap:6}}>
            ← Volver a la Forja
          </div>
        </div>
      </div>
    );
  }

  return (
    <div style={{flex:1,display:"flex",flexDirection:"column",overflow:"hidden"}}>
      <div style={{flex:1,overflowY:"auto",padding:"8px 12px",display:"flex",flexDirection:"column",gap:0}}>
        {FORJA_INIT[side].map((h, idx) => {
          const state = getState(h);
          const isLocked = ["bloqueada_req","bloqueada_asc"].includes(state);
          const isComprada = state === "comprada";
          const isAvail = state === "disponible";
          const missing = h.req.filter(r => !purchased[r]);
          const missingNames = missing.map(r => allH.find(x => x.id===r)?.nombre || r);
          const totalNiv = isComprada ? h.params.reduce((a,p)=>a+params[p.id],0) : 0;
          const totalMax = h.params.length * 4;
          return (
            <div key={h.id}>
              <div style={{...cardStyle(isComprada?"#0d1a0d":C.surface, isComprada?"#1a3a1a":C.border),opacity:isLocked?0.45:1,cursor:isComprada?"pointer":"default",margin:"2px 0"}}
                onClick={() => isComprada && setDetalle(h.id)}>
                <div style={{width:24,height:24,borderRadius:"50%",flexShrink:0,display:"flex",alignItems:"center",justifyContent:"center",
                  background:isComprada?"#1e5a1e":isLocked?"#111":color+"22",
                  border:`1px solid ${isComprada?"#2a8a2a":isLocked?"#1a1a1a":color}`,fontSize:10,fontWeight:500,
                  color:isComprada?C.green:isLocked?"#2a2a2a":color}}>
                  {isComprada?"✓":isLocked?"🔒":idx+1}
                </div>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{color:isLocked?"#333":C.text,fontSize:12,fontWeight:500,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{h.nombre}</div>
                  <div style={{color:isLocked?"#222":C.dim,fontSize:9,marginTop:2}}>{h.desc}</div>
                  {missingNames.length > 0 && <div style={{color:"#3a2500",fontSize:8,marginTop:3}}>Req: {missingNames.slice(0,2).join(", ")}</div>}
                  {isComprada && <div style={{color:"#2a5a2a",fontSize:9,marginTop:4}}>Mejoras {totalNiv}/{totalMax}</div>}
                </div>
                <div style={{display:"flex",flexDirection:"column",alignItems:"center",gap:3,minWidth:72}}>
                  {isComprada ? (
                    <div style={{background:"#1a3a1a",border:`1px solid #2a5a2a`,borderRadius:8,padding:"5px 8px",width:"100%",textAlign:"center"}}>
                      <span style={{color:C.green,fontSize:9,fontWeight:500}}>VER MEJORAS</span>
                    </div>
                  ) : isAvail ? (
                    <>
                      <div style={btnStyle(color, frags>=h.coste)} onClick={(e)=>{e.stopPropagation();if(frags<h.coste)return;setFrags(f=>f-h.coste);setPurchased(p=>({...p,[h.id]:true}));}}>
                        <div style={{color:frags>=h.coste?color:C.dimmer,fontSize:9,fontWeight:500}}>DESBLOQUEAR</div>
                      </div>
                      <div style={{display:"flex",alignItems:"center",gap:2}}>
                        <span style={{color:frags>=h.coste?C.orange:"#3a2a1a",fontSize:9}}>⬡</span>
                        <span style={{color:frags>=h.coste?"#aaa":"#3a2a1a",fontSize:9}}>{h.coste}</span>
                      </div>
                    </>
                  ) : (
                    <div style={{background:"#111",border:`1px solid ${C.border}`,borderRadius:8,padding:"5px 8px",textAlign:"center",width:"100%"}}>
                      <span style={{color:"#2a2a3a",fontSize:9}}>{state==="bloqueada_asc"?`Asc. ${h.umbral}`:"BLOQUEADA"}</span>
                    </div>
                  )}
                </div>
              </div>
              {idx < FORJA_INIT[side].length-1 && (
                <div style={{display:"flex",justifyContent:"center",margin:"0 12px"}}>
                  <div style={{width:1,height:10,background:isComprada?"#1e5a1e":C.border}} />
                </div>
              )}
            </div>
          );
        })}
      </div>
      <div style={{display:"flex",padding:"0 10px",gap:4,background:"#0b0b18",borderTop:`1px solid #141428`}}>
        {[{k:"ofensiva",label:"⚔ Ataque",c:C.red},{k:"defensiva",label:"🛡 Defensa",c:C.blue}].map(t => (
          <div key={t.k} onClick={() => setSide(t.k)}
            style={{flex:1,textAlign:"center",padding:"10px 2px 8px",fontSize:10,fontWeight:500,cursor:"pointer",
              color:side===t.k?t.c:C.inactive, borderTop:`2px solid ${side===t.k?t.c:"transparent"}`}}>
            {t.label}
          </div>
        ))}
      </div>
    </div>
  );
}

// ── PERFIL ────────────────────────────────────────────────────────────────
function PerfilScreen() {
  return (
    <div style={{flex:1,overflowY:"auto",padding:"0 14px"}}>
      <div style={{display:"flex",alignItems:"center",gap:12,paddingBottom:8}}>
        <div style={{width:52,height:52,borderRadius:"50%",background:"#0f0a1e",border:`2px solid ${C.purple}`,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0,fontSize:24}}>👤</div>
        <div>
          <div style={{color:C.text,fontSize:14,fontWeight:500}}>Void Initiate</div>
          <div style={{color:C.dim,fontSize:10,marginTop:2}}>Tier I · Jugador desde v1.0</div>
          <div style={{display:"flex",alignItems:"center",gap:6,marginTop:5}}>
            <div style={{height:3,width:80,background:"#1a1a2e",borderRadius:2,overflow:"hidden"}}>
              <div style={{width:"62%",height:"100%",background:C.purple}} />
            </div>
            <span style={{color:C.dim,fontSize:9}}>Tier II: asc. 5.000</span>
          </div>
        </div>
      </div>
      <div style={{display:"flex",gap:6,paddingBottom:8}}>
        {[["ASCENSIÓN MÁX","1.847",C.cian],["PARTIDAS","312",C.text],["COMMANDERS","36",C.gold]].map(([k,v,c]) => (
          <div key={k} style={{flex:1,...cardStyle(),flexDirection:"column",justifyContent:"center",textAlign:"center"}}>
            <div style={{color:C.dim,fontSize:8,letterSpacing:0.5}}>{k}</div>
            <div style={{color:c,fontSize:15,fontWeight:500,marginTop:3}}>{v}</div>
          </div>
        ))}
      </div>
      <div style={{color:"#333",fontSize:9,letterSpacing:0.5,marginBottom:6}}>LOGROS</div>
      <div style={{display:"flex",flexDirection:"column",gap:6,paddingBottom:8}}>
        {LOGROS.map(l => (
          <div key={l.nombre} style={{...cardStyle(l.ok?"#0d1a0d":C.surface, l.ok?"#1a3a1a":C.border, 9), opacity:l.ok?1:0.45}}>
            <div style={{width:32,height:32,borderRadius:8,background:l.ok?"#1e5a1e":"#111",border:`1px solid ${l.ok?"#2a8a2a":C.border}`,display:"flex",alignItems:"center",justifyContent:"center",fontSize:14,flexShrink:0,color:l.ok?C.green:"#2a2a3a"}}>
              {l.ok?"✓":"🔒"}
            </div>
            <div style={{flex:1}}>
              <div style={{color:l.ok?"#aaa":"#333",fontSize:11,fontWeight:500}}>{l.nombre}</div>
              <div style={{color:l.ok?"#2a5a2a":"#222",fontSize:9,marginTop:2}}>{l.desc}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── TIENDA ────────────────────────────────────────────────────────────────
function TiendaScreen() {
  return (
    <div style={{flex:1,overflowY:"auto",padding:"0 14px"}}>
      <div style={{color:"#333",fontSize:9,letterSpacing:0.5,margin:"6px 0 4px"}}>PACKS DE PLATINUM</div>
      <div style={{display:"flex",flexDirection:"column",gap:7,marginBottom:8}}>
        {PACKS.map(p => (
          <div key={p.cantidad} style={{background:p.highlight?"#120d00":C.surface, border:`${p.highlight?"1.5px":"1px"} solid ${p.highlight?C.orange:C.border}`,borderRadius:11,padding:"11px 14px",display:"flex",alignItems:"center",justifyContent:"space-between"}}>
            <div style={{display:"flex",alignItems:"center",gap:10,flex:1}}>
              <div style={{width:36,height:36,borderRadius:8,background:p.highlight?"#2a1500":"#111",border:`1px solid ${p.highlight?C.orange:C.border}`,display:"flex",alignItems:"center",justifyContent:"center",color:C.plat,fontSize:16,flexShrink:0}}>◆</div>
              <div>
                <div style={{display:"flex",alignItems:"center",gap:5}}>
                  <span style={{color:C.text,fontSize:13,fontWeight:500}}>{p.cantidad} Platinum</span>
                  {p.bonus && <span style={{color:C.orange,fontSize:10}}>{p.bonus}</span>}
                </div>
                <div style={{color:p.highlight?C.orange:"#333",fontSize:9,marginTop:2}}>{p.highlight?"MEJOR VALOR":" "}</div>
              </div>
            </div>
            <div style={{background:p.highlight?C.orange:"#111",border:`1px solid ${p.highlight?C.orange:C.border}`,borderRadius:8,padding:"6px 12px",cursor:"pointer",flexShrink:0}}>
              <span style={{color:p.highlight?"#fff":"#444",fontSize:11,fontWeight:500}}>{p.precio}</span>
            </div>
          </div>
        ))}
      </div>
      <div style={{color:"#333",fontSize:9,letterSpacing:0.5,marginBottom:4}}>OTROS</div>
      <div style={{display:"flex",flexDirection:"column",gap:7,paddingBottom:8}}>
        {[{nombre:"Sin anuncios",desc:"Elimina los anuncios para siempre",precio:"2,99€"},{nombre:"Starter Pack",desc:"200 Platinum + boost x2 primera semana",precio:"1,99€"}].map(o => (
          <div key={o.nombre} style={{background:C.surface,border:`1px solid ${C.border}`,borderRadius:11,padding:"11px 14px",display:"flex",alignItems:"center",justifyContent:"space-between"}}>
            <div style={{display:"flex",alignItems:"center",gap:10,flex:1}}>
              <div style={{width:36,height:36,borderRadius:8,background:"#111",border:`1px solid ${C.border}`,display:"flex",alignItems:"center",justifyContent:"center",color:"#555",fontSize:16,flexShrink:0}}>★</div>
              <div>
                <div style={{color:C.text,fontSize:13,fontWeight:500}}>{o.nombre}</div>
                <div style={{color:"#333",fontSize:9,marginTop:2}}>{o.desc}</div>
              </div>
            </div>
            <div style={{background:"#111",border:`1px solid ${C.border}`,borderRadius:8,padding:"6px 12px",cursor:"pointer",flexShrink:0}}>
              <span style={{color:"#444",fontSize:11,fontWeight:500}}>{o.precio}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── MAIN HUB ──────────────────────────────────────────────────────────────
export default function App() {
  const [tab, setTab] = useState("home");
  const [gold, setGold] = useState(248500);
  const [frags, setFrags] = useState(50000);

  const navItems = [
    {k:"home",icon:"🏠",label:"Home",color:C.cian},
    {k:"nexus",icon:"⚡",label:"Nexus",color:C.gold},
    {k:"forja",icon:"🔥",label:"Forja",color:C.orange,locked:true},
    {k:"perfil",icon:"👤",label:"Perfil",color:C.purple},
    {k:"tienda",icon:"🛒",label:"Tienda",color:C.orange},
  ];

  const headerRight = {
    home: (
      <div style={{display:"flex",gap:5}}>
        {[[C.gold,"©",fmt(gold),"Gold"],[C.orange,"⬡",fmt(frags),"Frag"],[C.plat,"◆","34","Plat"]].map(([c,s,v,l]) => (
          <div key={l} style={{display:"flex",alignItems:"center",gap:4,background:"#111120",border:`1px solid #1e1e38`,borderRadius:16,padding:"4px 8px"}}>
            <span style={{color:c,fontSize:11,fontWeight:700}}>{s}</span>
            <div>
              <div style={{color:"#bbb",fontSize:10,lineHeight:1.2}}>{v}</div>
              <div style={{color:"#444",fontSize:8}}>{l}</div>
            </div>
          </div>
        ))}
      </div>
    ),
    nexus: <div style={{display:"flex",alignItems:"center",gap:5,background:"#111120",border:`1px solid #1e1e38`,borderRadius:14,padding:"4px 10px"}}><span style={{color:C.gold,fontSize:12,fontWeight:700}}>©</span><span style={{color:"#ddd",fontSize:11}}>{gold.toLocaleString()}</span></div>,
    forja: <div style={{display:"flex",alignItems:"center",gap:5,background:"#111120",border:`1px solid #1e1e38`,borderRadius:14,padding:"4px 10px"}}><span style={{color:C.orange,fontSize:12,fontWeight:700}}>⬡</span><span style={{color:"#ddd",fontSize:11}}>{frags.toLocaleString()}</span></div>,
    perfil: null,
    tienda: <div style={{display:"flex",alignItems:"center",gap:5,background:"#111120",border:`1px solid #1e1e38`,borderRadius:14,padding:"4px 10px"}}><span style={{color:C.plat,fontSize:11,fontWeight:700}}>◆</span><span style={{color:"#ddd",fontSize:11}}>34</span></div>,
  };

  const headerIcons = {home:{icon:"🏠",color:C.cian,title:"Home"},nexus:{icon:"⚡",color:C.gold,title:"Nexus"},forja:{icon:"🔥",color:C.orange,title:"Forja"},perfil:{icon:"👤",color:C.purple,title:"Perfil"},tienda:{icon:"🛒",color:C.orange,title:"Tienda"}};
  const hi = headerIcons[tab] || headerIcons.home;

  return (
    <div style={{display:"flex",justifyContent:"center",alignItems:"center",minHeight:"100vh",background:"#050508",padding:16}}>
      <div style={{background:C.bg,borderRadius:28,border:`1.5px solid #1a1a2e`,width:340,height:660,overflow:"hidden",fontFamily:"system-ui,sans-serif",display:"flex",flexDirection:"column"}}>

        <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",padding:"10px 18px 4px",flexShrink:0}}>
          <span style={{color:"#888",fontSize:11,fontWeight:500}}>21:34</span>
          <span style={{color:"#888",fontSize:11}}>▲ ⬛</span>
        </div>

        <div style={{padding:"6px 16px 8px",display:"flex",alignItems:"center",justifyContent:"space-between",flexShrink:0}}>
          <div style={{display:"flex",alignItems:"center",gap:8}}>
            <span style={{fontSize:16}}>{hi.icon}</span>
            <span style={{color:hi.color,fontSize:15,fontWeight:500}}>{hi.title}</span>
          </div>
          {headerRight[tab]}
        </div>

        <div style={{flex:1,overflow:"hidden",display:"flex",flexDirection:"column"}}>
          {tab==="home" && <HomeScreen gold={gold} frags={frags} plat={34} />}
          {tab==="nexus" && <NexusScreen gold={gold} setGold={setGold} />}
          {tab==="forja" && <ForjaScreen frags={frags} setFrags={setFrags} />}
          {tab==="perfil" && <PerfilScreen />}
          {tab==="tienda" && <TiendaScreen />}
        </div>

        <div style={{display:"flex",background:"#0b0b18",borderTop:`1px solid #141428`,padding:"8px 4px 14px",flexShrink:0}}>
          {navItems.map(n => (
            <div key={n.k} onClick={() => setTab(n.k)}
              style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",gap:3,cursor:"pointer",padding:"4px 0"}}>
              <div style={{position:"relative",display:"inline-flex"}}>
                <span style={{fontSize:20,filter:tab===n.k?"none":"grayscale(1) brightness(0.3)"}}>{n.icon}</span>
                {n.locked && <span style={{position:"absolute",top:-2,right:-6,fontSize:9,color:"#2a2a40"}}>🔒</span>}
              </div>
              <span style={{fontSize:9,fontWeight:500,color:tab===n.k?n.color:C.inactive}}>{n.label}</span>
            </div>
          ))}
        </div>

      </div>
    </div>
  );
}
