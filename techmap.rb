techniques = {}

f = open('doc/techniques.txt')
while line = f.gets
  id, name = line.chomp.split(/\t/)
  techniques[name] = id
end
f.close

aliases = {}

f = open('doc/alias.txt')
while line = f.gets
  from, to = line.chomp.split(/\t/)
  aliases[to] = from
end
f.close

for to, from in aliases
  techniques[to] = techniques[from]
end

for name, id in techniques
  puts [name, id].join("\t")
end
