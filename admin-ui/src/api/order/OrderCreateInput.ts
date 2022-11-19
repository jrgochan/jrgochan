import { CustomerWhereUniqueInput } from "../customer/CustomerWhereUniqueInput";
import { CustomerCreateNestedManyWithoutOrdersInput } from "./CustomerCreateNestedManyWithoutOrdersInput";
import { ProductWhereUniqueInput } from "../product/ProductWhereUniqueInput";

export type OrderCreateInput = {
  customer?: CustomerWhereUniqueInput | null;
  customers?: CustomerCreateNestedManyWithoutOrdersInput;
  discount?: number | null;
  product?: ProductWhereUniqueInput | null;
  quantity?: number | null;
  totalPrice?: number | null;
};
