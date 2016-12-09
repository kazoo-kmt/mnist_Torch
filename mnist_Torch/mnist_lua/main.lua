if torch == nil then
  require "torch"
end

a = torch.rand(100,1)
b = torch.rand(1,100)
c = torch.dot(a,b)

print (c)
