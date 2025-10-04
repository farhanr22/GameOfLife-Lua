-- nice looking oscillating patterns, from https://conwaylife.com/

patterns = {
'12bo$3o7bobo$5bo4bobo$b2obob2o$4bo4b2o$6bo4bo$3bo4bobo$3bobo4bo$2bo4bo$3b2o4bo$6b2obob2o$bobo4bo$bobo7b3o$bo!',
'7bo$6b2o$5b2o$4bo$3bob4o$2bobo4bo$b2obob2obo2b2o$2o2bob2obob2o$4bo4bobo$5b4obo$9bo$7b2o$6b2o$6bo!',
'2o$bo$bobo9b2o$2bobo8bo$11bobo$11b2o$5b2o$5b2ob2o$8b2o$2b2o$bobo$bo8bobo$2o9bobo$13bo$13b2o!',
'bo11b$b3o7b2o$4bo6bob$3b2o4bobob$9b2o2b$6bo6b$4b2obo5b2$2bo3bo2bo3b$bob2o4bo3b$bo6bo4b$2o7b3ob$11bo!',
'5bo5b$4bobo4b$5bo5b2$3b5o3b$obo5bobo$2obo3bob2o$3bo3bo3b$3bo3bo3b$4b3o4b2$4b2obo3b$4bob2o!'
}

function getRandomPattern()
	return patterns[math.random(1,#patterns)]
end