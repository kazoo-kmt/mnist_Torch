if torch == nil then
  require "torch"
end

-- torch.setdefaulttensortype('torch.FloatTensor')
torch.setdefaulttensortype('torch.DoubleTensor')
model = ""

function loadNeuralNetwork(path)
  print (path)
  print ("Loaded Neural Network -- Success")
  model = torch.load(path)

  print ("Model Architecture --\n")
  print (model)
  print ("---------------------\n")
end

function forwardNeuralNetwork(imageInput)
  local output = model:forward(imageInput)
  local _, index = torch.max(output, 1) -- max index
  local digit = (index[1] - 1) % 10
  print(digit)
  return digit
end
