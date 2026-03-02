pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- the depths
-- a roguelike rpg

-- constants
t_wall,t_floor,t_stair=0,1,2
mw,mh=32,32
state="title"
msgs={}
flr_num=0

-- enemy templates {name,spr,hp,atk,def,xp}
e_tpl={
 {"slime",5,5,2,0,8},
 {"skel",6,8,4,2,12},
 {"demon",7,14,6,3,22}
}
-- item templates {name,spr,type,val}
i_tpl={
 {"potion",8,"hp",6},
 {"sword",9,"atk",2},
 {"shield",10,"def",2}
}

-- skill definitions {name, desc, key}
all_skills={
 {n="might",d="+1 attack",k="atk"},
 {n="armor",d="+1 defense",k="def"},
 {n="vitality",d="+5 max hp",k="vit"},
 {n="vampirism",d="heal on kill",k="vamp"},
 {n="fury",d="crit chance",k="fury"},
 {n="far sight",d="+2 view range",k="sight"},
 {n="regen",d="heal each floor",k="regen"},
 {n="dodge",d="evade attacks",k="dodge"}
}
-- skill selection state
skill_opts={}
skill_sel=0
-- pause state
music_on=true
pause_sel=1

function msg(s)
 add(msgs,s)
 if #msgs>3 then deli(msgs,1) end
end

------------------------------
-- dungeon generation
------------------------------
function gen_dungeon()
 grid={}
 for y=0,mh-1 do
  grid[y]={}
  for x=0,mw-1 do
   grid[y][x]=t_wall
  end
 end

 -- generate rooms
 rooms={}
 for i=1,30 do
  local rw=3+flr(rnd(5))
  local rh=3+flr(rnd(4))
  local rx=1+flr(rnd(mw-rw-2))
  local ry=1+flr(rnd(mh-rh-2))
  local ok=true
  for r in all(rooms) do
   if rx<=r.x+r.w+1 and r.x<=rx+rw+1
   and ry<=r.y+r.h+1 and r.y<=ry+rh+1 then
    ok=false break
   end
  end
  if ok then
   add(rooms,{x=rx,y=ry,w=rw,h=rh})
   for y=ry,ry+rh-1 do
    for x=rx,rx+rw-1 do
     grid[y][x]=t_floor
    end
   end
  end
  if #rooms>=7 then break end
 end

 -- connect rooms with corridors
 for i=2,#rooms do
  local a,b=rooms[i-1],rooms[i]
  local ax=flr(a.x+a.w/2)
  local ay=flr(a.y+a.h/2)
  local bx=flr(b.x+b.w/2)
  local by=flr(b.y+b.h/2)
  local x0,x1=min(ax,bx),max(ax,bx)
  for x=x0,x1 do grid[ay][x]=t_floor end
  local y0,y1=min(ay,by),max(ay,by)
  for y=y0,y1 do grid[y][bx]=t_floor end
 end

 -- place stairs in last room
 local lr=rooms[#rooms]
 grid[flr(lr.y+lr.h/2)][flr(lr.x+lr.w/2)]=t_stair

 -- place player in first room
 local fr=rooms[1]
 p.x=flr(fr.x+fr.w/2)
 p.y=flr(fr.y+fr.h/2)

 -- spawn enemies
 enemies={}
 for i=2,#rooms do
  local r=rooms[i]
  local ne=1+flr(rnd(1+flr(flr_num/3)))
  if ne>3 then ne=3 end
  for j=1,ne do
   local tier=min(3,1+flr(rnd(1+flr_num/3)))
   local et=e_tpl[tier]
   add(enemies,{
    x=r.x+1+flr(rnd(max(1,r.w-2))),
    y=r.y+1+flr(rnd(max(1,r.h-2))),
    s=et[2],n=et[1],
    hp=et[3]+flr(flr_num*1.5),
    atk=et[4]+flr(flr_num*0.5),
    def=et[5]+flr(flr_num/2),
    xp=et[6]+flr_num
   })
  end
 end

 -- spawn items (potions weighted)
 items={}
 for r in all(rooms) do
  if rnd(100)<45 then
   local ri=rnd(100)
   local it
   if ri<40 then it=i_tpl[1]
   elseif ri<70 then it=i_tpl[2]
   else it=i_tpl[3] end
   add(items,{
    x=r.x+1+flr(rnd(max(1,r.w-2))),
    y=r.y+1+flr(rnd(max(1,r.h-2))),
    s=it[2],n=it[1],t=it[3],v=it[4]
   })
  end
 end

 -- reset visibility
 seen={}
 lit={}
end

------------------------------
-- field of view
------------------------------
function update_fov()
 lit={}
 local r=5+p.sk.sight*2
 for dy=-r,r do
  for dx=-r,r do
   if dx*dx+dy*dy<=r*r then
    local tx,ty=p.x+dx,p.y+dy
    if tx>=0 and tx<mw and ty>=0 and ty<mh then
     local k=ty*mw+tx
     lit[k]=true
     seen[k]=true
    end
   end
  end
 end
end

------------------------------
-- combat
------------------------------
function do_attack(a,d)
 -- fury: crit chance
 local dmg=max(1,a.atk-d.def+flr(rnd(3)))
 if a==p and p.sk.fury>0 and rnd(100)<p.sk.fury*15 then
  dmg=flr(dmg*2)
  msg("critical!")
 end
 -- dodge: defender evades
 if d==p and p.sk.dodge>0 and rnd(100)<p.sk.dodge*12 then
  msg("dodged!")
  return 0
 end
 d.hp-=dmg
 return dmg
end

function check_lvlup()
 if p.xp>=p.xpn then
  p.lvl+=1
  p.xp-=p.xpn
  p.xpn=flr(p.xpn*1.7)
  p.maxhp+=3
  p.hp=min(p.hp+4,p.maxhp)
  -- pick 3 random skills
  skill_opts={}
  local pool={}
  for s in all(all_skills) do add(pool,s) end
  for i=1,3 do
   if #pool==0 then break end
   local idx=1+flr(rnd(#pool))
   add(skill_opts,pool[idx])
   deli(pool,idx)
  end
  skill_sel=1
  state="lvlup"
  sfx(5)
 end
end

function apply_skill(sk)
 local k=sk.k
 if k=="atk" then p.atk+=1
 elseif k=="def" then p.def+=1
 elseif k=="vit" then
  p.maxhp+=5 p.hp=min(p.hp+5,p.maxhp)
 end
 p.sk[k]=(p.sk[k] or 0)+1
 msg("learned "..sk.n.."!")
end

------------------------------
-- enemy ai
------------------------------
function update_enemies()
 for e in all(enemies) do
  local dx,dy=p.x-e.x,p.y-e.y
  local dist=abs(dx)+abs(dy)
  if dist<=1 then
   local dmg=do_attack(e,p)
   msg(e.n.." -"..dmg.."hp")
   sfx(1)
   if p.hp<=0 then
    state="dead" sfx(4)
   end
  elseif dist<=6 then
   local mx,my=0,0
   if abs(dx)>=abs(dy) then
    mx=dx>0 and 1 or -1
   else
    my=dy>0 and 1 or -1
   end
   local nx,ny=e.x+mx,e.y+my
   if nx>=0 and nx<mw and ny>=0 and ny<mh
   and grid[ny][nx]!=t_wall then
    local blk=false
    for o in all(enemies) do
     if o!=e and o.x==nx and o.y==ny then blk=true break end
    end
    if nx==p.x and ny==p.y then blk=true end
    if not blk then e.x,e.y=nx,ny end
   end
  end
 end
end

------------------------------
-- core callbacks
------------------------------
function _init()
 state="title"
end

function start_game()
 p={x=0,y=0,hp=15,maxhp=15,
    atk=4,def=0,lvl=1,xp=0,xpn=20,
    sk={atk=0,def=0,vit=0,vamp=0,
        fury=0,sight=0,regen=0,dodge=0}}
 flr_num=1
 msgs={}
 gen_dungeon()
 update_fov()
 msg("welcome to the depths!")
 state="play"
 if music_on then music(0) end
end

function _update()
 if state=="title" then
  if btnp(4) or btnp(5) then start_game() end
 elseif state=="play" then
  update_play()
 elseif state=="dead" then
  if btnp(4) or btnp(5) then state="title" music(-1) end
 elseif state=="lvlup" then
  update_lvlup()
 elseif state=="pause" then
  update_pause()
 end
end

function update_lvlup()
 if btnp(2) then skill_sel=max(1,skill_sel-1) sfx(0) end
 if btnp(3) then skill_sel=min(#skill_opts,skill_sel+1) sfx(0) end
 if btnp(4) or btnp(5) then
  apply_skill(skill_opts[skill_sel])
  state="play"
  sfx(3)
  -- check for another pending level up
  check_lvlup()
 end
end

function update_pause()
 if btnp(2) then pause_sel=max(1,pause_sel-1) sfx(0) end
 if btnp(3) then pause_sel=min(3,pause_sel+1) sfx(0) end
 if btnp(4) or btnp(5) then
  if pause_sel==1 then
   -- resume
   state="play" sfx(0)
  elseif pause_sel==2 then
   -- toggle music
   music_on=not music_on
   if music_on then music(0) else music(-1) end
   sfx(3)
  elseif pause_sel==3 then
   -- quit to title
   state="title" music(-1)
  end
 end
end

function update_play()
 -- pause check
 if btnp(4) then
  pause_sel=1
  state="pause"
  sfx(0)
  return
 end
 local dx,dy=0,0
 if btnp(0) then dx=-1
 elseif btnp(1) then dx=1
 elseif btnp(2) then dy=-1
 elseif btnp(3) then dy=1
 else return end

 local nx,ny=p.x+dx,p.y+dy
 if nx<0 or nx>=mw or ny<0 or ny>=mh then return end
 if grid[ny][nx]==t_wall then return end

 -- bump attack (player strikes first)
 for e in all(enemies) do
  if e.x==nx and e.y==ny then
   local dmg=do_attack(p,e)
   msg("hit "..e.n.." -"..dmg)
   sfx(1)
   if e.hp<=0 then
    msg(e.n.." +"..e.xp.."xp")
    p.xp+=e.xp
    -- vampirism: heal on kill
    if p.sk.vamp>0 then
     local heal=p.sk.vamp*2
     p.hp=min(p.hp+heal,p.maxhp)
     msg("+"..heal.." vamp")
    end
    del(enemies,e)
    check_lvlup()
    sfx(2)
   else
    update_enemies()
   end
   update_fov()
   return
  end
 end

 -- move
 p.x,p.y=nx,ny
 sfx(0)

 -- pickup items
 for it in all(items) do
  if it.x==p.x and it.y==p.y then
   if it.t=="hp" then
    p.hp=min(p.hp+it.v,p.maxhp)
    msg("+"..it.v.." hp")
   elseif it.t=="atk" then
    p.atk+=it.v
    msg("atk +"..it.v)
   elseif it.t=="def" then
    p.def+=it.v
    msg("def +"..it.v)
   end
   del(items,it)
   sfx(3)
  end
 end

 -- stairs
 if grid[p.y][p.x]==t_stair then
  flr_num+=1
  -- regen: heal on new floor
  if p.sk.regen>0 then
   local heal=p.sk.regen*3
   p.hp=min(p.hp+heal,p.maxhp)
   msg("+"..heal.." regen")
  end
  gen_dungeon()
  msg("floor "..flr_num)
  sfx(3)
 end

 update_enemies()
 update_fov()
end

------------------------------
-- drawing
------------------------------
function _draw()
 if state=="title" then
  draw_title()
 elseif state=="play" then
  draw_game()
 elseif state=="dead" then
  draw_dead()
 elseif state=="lvlup" then
  draw_game()
  draw_lvlup()
 elseif state=="pause" then
  draw_game()
  draw_pause()
 end
end

function draw_pause()
 -- dark overlay
 rectfill(20,28,107,92,0)
 rect(20,28,107,92,7)
 rect(21,29,106,91,5)
 -- title
 print("paused",50,32,7)
 line(28,40,99,40,5)
 -- options
 local opts={"resume","music: "..(music_on and "on" or "off"),"quit"}
 for i=1,3 do
  local y=44+(i-1)*14
  local col=6
  if i==pause_sel then
   rectfill(24,y-1,103,y+7,1)
   col=7
   print("\x91",26,y,11)
  end
  print(opts[i],36,y,col)
 end
 print("\x83\x94:move \x97:select",28,86,5)
end

function draw_lvlup()
 -- dark overlay
 rectfill(10,16,117,110,0)
 rect(10,16,117,110,7)
 rect(11,17,116,109,5)
 print("level up! lv"..p.lvl,34,20,11)
 print("choose a skill:",34,30,7)
 for i=1,#skill_opts do
  local s=skill_opts[i]
  local y=40+(i-1)*18
  local col=6
  if i==skill_sel then
   rectfill(14,y-2,113,y+11,1)
   col=7
   print("\x91",16,y+1,11)
  end
  print(s.n,26,y,col)
  print(s.d,26,y+7,5)
  -- show stack count if >0
  local cnt=p.sk[s.k] or 0
  if cnt>0 then
   print("x"..cnt,100,y,9)
  end
 end
 print("\x97 select",46,100,6)
end

function draw_title()
 cls(0)
 print("\x8e the depths \x8f",30,24,7)
 print("a roguelike rpg",34,36,6)
 for i=0,15 do
  rectfill(i*8,56,i*8+6,62,i)
 end
 print("\x97 to start",42,76,11)
 print("\x8b\x91\x83\x94:move",38,92,5)
 print("bump into foes to attack",16,100,5)
end

function draw_dead()
 cls(0)
 print("you have perished",30,24,8)
 print("floor reached: "..flr_num,28,42,7)
 print("level: "..p.lvl,44,50,7)
 print("enemies slain!",30,58,6)
 print("\x97 to retry",40,80,11)
end

function draw_game()
 cls(0)
 local cx=p.x*8-60
 local cy=p.y*8-56
 camera(cx,cy)

 -- draw visible tiles
 local tx0=flr(cx/8)-1
 local ty0=flr(cy/8)-1
 for ty=ty0,ty0+17 do
  for tx=tx0,tx0+17 do
   if tx>=0 and tx<mw and ty>=0 and ty<mh then
    local k=ty*mw+tx
    local px,py=tx*8,ty*8
    if lit[k] then
     local t=grid[ty][tx]
     if t==t_wall then
      spr(1,px,py)
     elseif t==t_floor then
      spr(2,px,py)
     elseif t==t_stair then
      spr(2,px,py)
      spr(4,px,py)
     end
    elseif seen[k] then
     local t=grid[ty][tx]
     if t==t_wall then
      rectfill(px,py,px+7,py+7,1)
     elseif t==t_floor or t==t_stair then
      pset(px+3,py+3,1)
     end
    end
   end
  end
 end

 -- draw items in lit area
 for it in all(items) do
  if lit[it.y*mw+it.x] then
   spr(it.s,it.x*8,it.y*8)
  end
 end

 -- draw enemies in lit area
 for e in all(enemies) do
  if lit[e.y*mw+e.x] then
   spr(e.s,e.x*8,e.y*8)
  end
 end

 -- draw player
 spr(3,p.x*8,p.y*8)

 -- hud (fixed position)
 camera()
 rectfill(0,0,127,8,0)
 rectfill(0,104,127,127,0)

 -- hp bar
 local hpw=flr(p.hp/p.maxhp*38)
 rectfill(1,1,39,6,0)
 rectfill(1,1,1+hpw,6,8)
 rect(1,1,39,6,7)
 print(p.hp.."/"..p.maxhp,3,1,7)

 -- stats
 print("f"..flr_num,44,1,6)
 print("lv"..p.lvl,60,1,11)
 print("atk"..p.atk,80,1,9)
 print("def"..p.def,104,1,12)

 -- messages
 for i=1,#msgs do
  print(msgs[i],2,105+(i-1)*8,7)
 end
end
__gfx__
00000000155555510000000000ddd00000000000000000000077700008000800000000000000007000ccc0000000000000000000000000000000000000000000
0000000055115511000500000d7d7d000000006000000000070707000088800000060000000007600ccccc000000000000000000000000000000000000000000
00000000511111110000000000ddd0000000066000bbb0000077700008a8a80000666000000076000ccacc000000000000000000000000000000000000000000
00000000555555550000000000ccc000000066600b7b7b00000700000088800000888000000760000caaac000000000000000000000000000000000000000000
0000000055551555000000000ccccc00000666600bbbbb000677760008888800088e8800047600000ccacc000000000000000000000000000000000000000000
00000000115511550000000000ccc00000666660bbbbbbb00007000000888000088888000040000000ccc0000000000000000000000000000000000000000000
00000000111151110500000000404000066666603bbbbb3000707000002020000088800000040000000c00000000000000000000000000000000000000000000
00000000555555550000000000404000000000000333330000707000022002200000000000000000000000000000000000000000000000000000000000000000
__gff__
0001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200001863000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003067024655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400003067024650186350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000241502b150301500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000c67006650066450663500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000024150281502b1503016030155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000c1400c1400c1400c1401414014140141401414016140161401614016140131401314013140131400c1400c1400c1400c140111401114011140111400f1400f1400f1400f14013140131401314013140
00100000240350000027035000002b0350000029035000002703500000240350000027035000001f0350000020035000001f035000001d035000001b035000001d035000001f0350000022035000001f03500000
001000001b5201b5201b5201b5201b5201b5201b5201b5201f5201f5201f5201f5201f5201f5201f5201f5201b5201b5201b5201b5201b5201b5201b5201b5201f5201f5201f5201f5201f5201f5201f5201f520
001000000663000000246200000006630000002462000000066300000024620000000663000000246200000006630000002462000000066300000024620000000663000000246200000006630000002462000000
001000000f1400f1400f1400f1401114011140111401114013140131401314013140131401314013140131401414014140141401414016140161401614016140131401314013140131400c1400c1400c1400c140
00100000270350000029035000002b035000002c035000002b0350000029035000002703500000240350000027035000002b03500000290350000027035000002403500000270350000024035000002405500000
__music__
01 06070809
02 0a0b0809
