import { CustomerWhereUniqueInput } from "../customer/CustomerWhereUniqueInput";
import { CustomerUpdateManyWithoutOrdersInput } from "./CustomerUpdateManyWithoutOrdersInput";
import { ProductWhereUniqueInput } from "../product/ProductWhereUniqueInput";

export type OrderUpdateInput = {
  customer?: CustomerWhereUniqueInput | null;
  customers?: CustomerUpdateManyWithoutOrdersInput;
  discount?: number | null;
  product?: ProductWhereUniqueInput | null;
  quantity?: number | null;
  totalPrice?: number | null;
};
