import { AddressWhereUniqueInput } from "../address/AddressWhereUniqueInput";
import { OrderWhereUniqueInput } from "../order/OrderWhereUniqueInput";
import { OrderCreateNestedManyWithoutCustomersInput } from "./OrderCreateNestedManyWithoutCustomersInput";

export type CustomerCreateInput = {
  address?: AddressWhereUniqueInput | null;
  email?: string | null;
  firstName?: string | null;
  lastName?: string | null;
  location?: OrderWhereUniqueInput | null;
  orders?: OrderCreateNestedManyWithoutCustomersInput;
  phone?: string | null;
};
